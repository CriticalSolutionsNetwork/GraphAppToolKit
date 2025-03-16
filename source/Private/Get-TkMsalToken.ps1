<#
    .SYNOPSIS
        Retrieves an OAuth2 token using various authentication methods.
    .DESCRIPTION
        The Get-TkMsalToken function retrieves an OAuth2 token for accessing APIs such as Microsoft Graph.
        It supports multiple authentication methods including client certificate, client secret, and managed identity.
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
        $token = Get-TkMsalToken -ClientId 'your-client-id' -TenantId 'your-tenant-id' -ClientSecret $secureClientSecret
    .EXAMPLE
        $token = Get-TkMsalToken -ClientId 'your-client-id' -TenantId 'your-tenant-id' -ClientCertificate $cert
    .EXAMPLE
        $token = Get-TkMsalToken -ClientId 'your-client-id' -TenantId 'your-tenant-id' -UseManagedIdentity

    .NOTES
        This function requires the MSAL.PS module for token acquisition.
#>
function Get-TkMsalToken {
    [CmdletBinding(DefaultParameterSetName = 'ClientCertificate')]
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
        if (-not $script:LogString) {
            #Write-AuditLog -Start
        }
        else {
            #Write-AuditLog -BeginFunction
        }
        # Define Authority URL based on selected cloud type
        switch ($AuthorityType) {
            'Global' { $Authority = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" }
            'AzureGov' { $Authority = "https://login.microsoftonline.us/$TenantId/oauth2/v2.0/token" }
            'China' { $Authority = "https://login.chinacloudapi.cn/$TenantId/oauth2/v2.0/token" }
        }
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq 'ManagedIdentity') {
            # 🟢 Managed Identity Authentication (Only Works in Azure-hosted Environments)
            try {
                # 📝 Construct the URL for requesting an access token from the Azure Instance Metadata Service (IMDS)
                # This URL is specific to Managed Identity authentication in Azure VMs, Azure Functions, App Services, etc.
                $uri = 'http://169.254.169.254/metadata/identity/oauth2/token?resource=https://graph.microsoft.com&api-version=2019-08-01'
                # 📝 Invoke-RestMethod sends a request to retrieve an OAuth2 token for the specified resource (Graph API)
                # 🔹 Managed Identity requires a GET request (unlike client secret/cert auth which use POST)
                $Response = Invoke-RestMethod `
                    -Uri $uri `
                    -Method Get `
                    -Headers @{ 'Metadata' = 'true' } ` # 🔹 Mandatory header to indicate this is an IMDS request
                -ErrorAction Stop # 🔹 Ensures an error is thrown if the request fails
                # 📝 Return only the access token from the API response
                return $Response.access_token
            }
            catch {
                # 🛑 If the request fails, print an error message and rethrow the exception
                Write-Error "Failed to obtain token via Managed Identity: $_"
                throw
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ClientCertificate') {
            # Validate Certificate Expiration
            if ($ClientCertificate.NotAfter -lt (Get-Date)) {
                Write-Error "The provided certificate has expired on $($ClientCertificate.NotAfter). Please use a valid certificate."
                return $null
            }
            # Generate JWT for client certificate authentication
            $JwtHeader = @{
                alg = 'RS256'
                typ = 'JWT'
                x5t = [Convert]::ToBase64String($ClientCertificate.GetCertHash()) -replace '\+', '-' -replace '/', '_' -replace '='
            }
            $IatTime = [int](Get-Date -UFormat %s)
            $ExpTime = $IatTime + 600  # 10 min expiration
            $JwtPayload = @{
                aud = $Authority
                exp = $ExpTime
                iat = $IatTime
                nbf = $IatTime
                iss = $ClientId
                sub = $ClientId
                jti = [guid]::NewGuid().ToString()
            }
            $Base64UrlEncode = { param ($String) [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($String)) -replace '\+', '-' -replace '/', '_' -replace '=' }
            $JwtHeaderEncoded = &$Base64UrlEncode (ConvertTo-Json $JwtHeader -Compress)
            $JwtPayloadEncoded = &$Base64UrlEncode (ConvertTo-Json $JwtPayload -Compress)
            $JwtToSign = "$JwtHeaderEncoded.$JwtPayloadEncoded"
            try {
                $Csp = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($ClientCertificate)
                $Signature = [Convert]::ToBase64String(
                    $Csp.SignData(
                        [System.Text.Encoding]::UTF8.GetBytes($JwtToSign),
                        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
                        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
                    )
                ) -replace '\+', '-' -replace '/', '_' -replace '='
            }
            catch {
                Write-Error "Failed to sign JWT: $_"
                throw
            }
            $ClientAssertion = "$JwtToSign.$Signature"
            $Body = @{
                client_id             = $ClientId
                client_assertion      = $ClientAssertion
                client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
                grant_type            = 'client_credentials'
                scope                 = $Scope
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ClientSecret') {
            $PlainClientSecret = ConvertFrom-SecureString -SecureString $ClientSecret -AsPlainText
            $Body = @{
                client_id     = $ClientId
                client_secret = $PlainClientSecret
                grant_type    = 'client_credentials'
                scope         = $Scope
            }
        }
    }
    end {
        try {
            return (Invoke-RestMethod -Method Post -Uri $Authority -ContentType 'application/x-www-form-urlencoded' -Body $Body -ErrorAction Stop).access_token
        }
        catch {
            Write-Error "Failed to obtain token: $_"
            throw
        }
    }
}
