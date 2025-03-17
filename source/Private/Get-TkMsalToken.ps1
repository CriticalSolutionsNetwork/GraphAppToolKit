<#
    .SYNOPSIS
        Retrieves an OAuth2 token for accessing Microsoft Graph or other APIs using various authentication methods.
    .DESCRIPTION
        The Get-TkMsalToken function supports three authentication methods:
        - Client Certificate
        - Client Secret
        - Managed Identity (only works in Azure-hosted environments)
    .PARAMETER ClientCertificate
        The X.509 certificate used for authentication. Example:
        $ClientCertificate = Get-Item Cert:\CurrentUser\My\<thumbprint>
    .PARAMETER ClientSecret
        The client secret used for authentication.
    .PARAMETER UseManagedIdentity
        Use Azure Managed Identity for authentication (only works in Azure-hosted environments).
    .PARAMETER ClientId
        The Azure AD application (client) ID.
    .PARAMETER TenantId
        The Azure AD tenant ID (GUID).
    .PARAMETER Scope
        The API scope for token access. Default is Microsoft Graph.
    .PARAMETER AuthorityType
        The authority type to use for authentication. Valid values are 'Global', 'AzureGov', and 'China'.
    .EXAMPLE
        Get-TkMsalToken -ClientCertificate $ClientCert -ClientId 'your-client-id' -TenantId 'your-tenant-id'
    .EXAMPLE
        Get-TkMsalToken -ClientSecret $ClientSecret -ClientId 'your-client-id' -TenantId 'your-tenant-id'
    .EXAMPLE
        Get-TkMsalToken -UseManagedIdentity -ClientId 'your-client-id' -TenantId 'your-tenant-id'
    .NOTES
        Author: DrIOSx
        Date: 2025-03-16
        Version: 1.0
#>
function Get-TkMsalToken {
    [CmdletBinding(DefaultParameterSetName = 'ClientCertificate')]
    [OutputType([string])]
    param (
        # Client Certificate
        [Parameter(
            ParameterSetName = 'ClientCertificate',
            Mandatory = $true,
            HelpMessage = `
                "The X.509 certificate used for authentication. Example: `n`$ClientCertificate = Get-Item Cert:\CurrentUser\My\<thumbprint>"
        )]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $ClientCertificate,
        # Client Secret
        [Parameter(
            ParameterSetName = 'ClientSecret',
            Mandatory = $true,
            HelpMessage = `
                'The client secret used for authentication.'
        )]
        [ValidateNotNullOrEmpty()]
        [SecureString]
        $ClientSecret,
        # Managed Identity
        [Parameter(
            ParameterSetName = 'ManagedIdentity',
            Mandatory = $true,
            HelpMessage = `
                'Use Azure Managed Identity for authentication (only works in Azure-hosted environments).'
        )]
        [switch]
        $UseManagedIdentity,
        # Client ID
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The Azure AD application (client) ID.'
        )]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]
        $ClientId,
        # Tenant ID
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The Azure AD tenant ID (GUID).'
        )]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]
        $TenantId,
        # Scope
        [Parameter(
            HelpMessage = 'The API scope for token access. Default is Microsoft Graph.'
        )]
        [ValidatePattern('^https:\/\/[a-zA-Z0-9.-]+\/[a-zA-Z0-9.-]+$')]
        [string]
        $Scope = 'https://graph.microsoft.com/.default',
        # Authority Type
        [Parameter(
            HelpMessage = 'The authority type to use for authentication.'
        )]
        [ValidateSet('Global', 'AzureGov', 'China')]
        [string]
        $AuthorityType = 'Global'
    )
    begin {
        if (-not $script:logString) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }
        # Define Authority URL based on selected cloud type
        switch ($AuthorityType) {
            'Global' { $authority = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" }
            'AzureGov' { $authority = "https://login.microsoftonline.us/$TenantId/oauth2/v2.0/token" }
            'China' { $authority = "https://login.chinacloudapi.cn/$TenantId/oauth2/v2.0/token" }
        }
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq 'ManagedIdentity') {
            # Managed Identity Authentication (Only Works in Azure-hosted Environments)
            try {
                $uri = 'http://169.254.169.254/metadata/identity/oauth2/token?resource=https://graph.microsoft.com&api-version=2019-08-01'
                $response = Invoke-RestMethod `
                    -Uri $uri `
                    -Method Get `
                    -Headers @{ 'Metadata' = 'true' } `
                    -ErrorAction Stop
                return $response.access_token
            }
            catch {
                Write-Error "Failed to obtain token via Managed Identity: $_"
                throw
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ClientCertificate') {
            if ($ClientCertificate.NotAfter -lt (Get-Date)) {
                Write-Error "The provided certificate has expired on $($ClientCertificate.NotAfter). Please use a valid certificate."
                throw "Certificate has expired."
            }
            $jwtHeader = @{
                alg = 'RS256'
                typ = 'JWT'
                x5t = [Convert]::ToBase64String($ClientCertificate.GetCertHash()) -replace '\+', '-' -replace '/', '_' -replace '='
            }
            $iatTime = [int](Get-Date (Get-Date).ToUniversalTime() -UFormat %s)
            $expTime = $iatTime + 600  # 10 min expiration
            $jwtPayload = @{
                aud = $authority
                exp = $expTime
                iat = $iatTime
                nbf = $iatTime
                iss = $ClientId
                sub = $ClientId
                jti = [guid]::NewGuid().ToString()
            }
            $base64UrlEncode = { param ($string) [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($string)) -replace '\+', '-' -replace '/', '_' -replace '=' }
            $jwtHeaderEncoded = &$base64UrlEncode (ConvertTo-Json $jwtHeader -Compress)
            $jwtPayloadEncoded = &$base64UrlEncode (ConvertTo-Json $jwtPayload -Compress)
            $jwtToSign = "$jwtHeaderEncoded.$jwtPayloadEncoded"
            try {
                $csp = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($ClientCertificate)
                $signature = [Convert]::ToBase64String(
                    $csp.SignData(
                        [System.Text.Encoding]::UTF8.GetBytes($jwtToSign),
                        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
                        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
                    )
                ) -replace '\+', '-' -replace '/', '_' -replace '='
            }
            catch {
                Write-Error "Failed to sign JWT: $_"
                throw
            }
            $clientAssertion = "$jwtToSign.$signature"
            $body = @{
                client_id             = $ClientId
                client_assertion      = $clientAssertion
                client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
                grant_type            = 'client_credentials'
                scope                 = $Scope
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ClientSecret') {
            $plainClientSecret = ConvertFrom-SecureString -SecureString $ClientSecret -AsPlainText
            $body = @{
                client_id     = $ClientId
                client_secret = $plainClientSecret
                grant_type    = 'client_credentials'
                scope         = $Scope
            }
        }
    }
    end {
        try {
            Write-AuditLog "Requesting token from $authority."
            $tokenResponse = (Invoke-RestMethod -Method Post -Uri $authority -ContentType 'application/x-www-form-urlencoded' -Body $body -ErrorAction Stop).access_token
            Write-AuditLog "Successfully obtained token from $authority."
            Write-AuditLog -EndFunction
            return $tokenResponse
        }
        catch {
            Write-AuditLog -Message "Failed to obtain token: $($_.Exception.Message)" -Severity "Error"
            throw
        }
    }
}
