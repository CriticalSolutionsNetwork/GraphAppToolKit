<#
    .SYNOPSIS
        Retrieves an OAuth 2.0 token using a client certificate for authentication.
    .DESCRIPTION
        The Get-TkMsalToken function generates a JSON Web Token (JWT) signed with a provided X.509 certificate and uses it to request an OAuth 2.0 token from Azure Active Directory (AAD). The token can be used to authenticate API requests to services like Microsoft Graph.
    .PARAMETER ClientCertificate
        The X.509 certificate used for authentication. Example:
        $ClientCertificate = Get-Item Cert:\CurrentUser\My\<thumbprint>
    .PARAMETER ClientId
        The Azure AD application (client) ID. Must be a valid GUID.
    .PARAMETER TenantId
        The Azure AD tenant ID (GUID). Example: 12345678-1234-1234-1234-1234567890ab.
    .PARAMETER Scope
        The API scope for token access. Default is Microsoft Graph. Must be a valid URL.
    .PARAMETER AuthorityType
        The authority type to use for authentication. Valid values are 'Global', 'AzureGov', and 'China'. Default is 'Global'.
    .EXAMPLE
        $ClientCertificate = Get-Item Cert:\CurrentUser\My\<thumbprint>
        $ClientId = "your-client-id"
        $TenantId = "your-tenant-id"
        $Token = Get-TkMsalToken -ClientCertificate $ClientCertificate -ClientId $ClientId -TenantId $TenantId
    .NOTES
        This function requires the 'Invoke-RestMethod' cmdlet to be available.
        The function logs the token expiration time using a custom Write-AuditLog function.
#>
function Get-TkMsalToken {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = `
            "The X.509 certificate used for authentication. Example: `n`$ClientCertificate = Get-Item Cert:\CurrentUser\My\<thumbprint>"
        )]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $ClientCertificate,
        #
        [Parameter(
            Mandatory = $true,
            HelpMessage = `
            'The Azure AD application (client) ID.'
        )]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]
        $ClientId,
        #
        [Parameter(
            Mandatory = $true,
            HelpMessage = `
            'The Azure AD tenant ID (GUID). Example: 12345678-1234-1234-1234-1234567890ab.')]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]
        $TenantId,
        #
        [Parameter(
            HelpMessage = `
            'The API scope for token access. Default is Microsoft Graph.'
        )]
        [ValidatePattern('^https:\/\/[a-zA-Z0-9.-]+\/[a-zA-Z0-9.-]+$')]
        [string]
        $Scope = 'https://graph.microsoft.com/.default',
        #
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
            'The authority type to use for authentication.'
        )]
        [ValidateSet('Global', 'AzureGov', 'China')]  # Removed invalid options
        [string]
        $AuthorityType = 'Global'
    )
    begin {
        if (-not $script:LogString) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }
        # Define Authority URL based on the chosen AuthorityType
        switch ($AuthorityType) {
            'Global' { $Authority = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" }
            'AzureGov' { $Authority = "https://login.microsoftonline.us/$TenantId/oauth2/v2.0/token" }
            'China' { $Authority = "https://login.chinacloudapi.cn/$TenantId/oauth2/v2.0/token" }
        }
        # Generate JWT Header
        $JwtHeader = @{
            alg = 'RS256'
            typ = 'JWT'
            x5t = [Convert]::ToBase64String($ClientCertificate.GetCertHash()) -replace '\+', '-' -replace '/', '_' -replace '='
        }
        # Generate Unix timestamps for `iat` and `exp`
        $IatTime = [int](Get-Date (Get-Date).ToUniversalTime() -UFormat %s)
        $ExpTime = $IatTime + 600  # JWT Expiration time (10 minutes from `iat`)
        # Generate JWT Payload
        $JwtPayload = @{
            aud = $Authority
            exp = $ExpTime
            iat = $IatTime
            iss = $ClientId
            sub = $ClientId
            jti = [guid]::NewGuid().ToString()
        }
    }
    process {
        # Convert JWT Header & Payload to Base64URL Encoding
        $Base64UrlEncode = { param ($String) [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($String)) -replace '\+', '-' -replace '/', '_' -replace '=' }
        $JwtHeaderEncoded = &$Base64UrlEncode (ConvertTo-Json $JwtHeader -Compress)
        $JwtPayloadEncoded = &$Base64UrlEncode (ConvertTo-Json $JwtPayload -Compress)
        # Combine Header & Payload
        $JwtToSign = "$JwtHeaderEncoded.$JwtPayloadEncoded"
        # Sign JWT with Certificate Private Key
        $Csp = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($ClientCertificate)
        $Signature = [Convert]::ToBase64String(
            $Csp.SignData(
                [System.Text.Encoding]::UTF8.GetBytes($JwtToSign),
                [System.Security.Cryptography.HashAlgorithmName]::SHA256,
                [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
            )
        ) -replace '\+', '-' -replace '/', '_' -replace '='
        $ClientAssertion = "$JwtToSign.$Signature"
        # Prepare Token Request
        $Body = @{
            client_id             = $ClientId
            client_assertion      = $ClientAssertion
            client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
            grant_type            = 'client_credentials'
            scope                 = $Scope
        }
    }
    end {
        try {
            # Get Token Using Invoke-RestMethod
            $Response = Invoke-RestMethod -Method Post -Uri $Authority -ContentType 'application/x-www-form-urlencoded' -Body $Body -ErrorAction Stop
            $tokenExpires = [System.TimeSpan]::FromSeconds($Response.expires_in)
            $tokenExpMinutes = $tokenExpires.Minutes
            $tokenExpTime = (Get-Date).AddMinutes($tokenExpMinutes)
            Write-AuditLog "The token expires today $($tokenExpTime.ToShortDateString()) in $tokenExpMinutes minutes at $($tokenExpTime.ToShortTimeString())."
            Write-AuditLog -EndFunction
            return $Response.access_token
        }
        catch {
            Write-Error "Failed to obtain token: $_"
            return $null
        }
    }
}

