<#
    .SYNOPSIS
    Initializes the Service Principal registration for a given application.
    .DESCRIPTION
    This function sets up the Service Principal registration for an application in Azure AD. It supports certificate-based authentication and grants OAuth2 permissions to the Service Principal.
    .PARAMETER AppRegistration
    The App Registration object containing various properties.
    .PARAMETER RequiredResourceAccessList
    The list of required resource access for the Service Principal.
    .PARAMETER Context
    The Microsoft Graph context that we are currently in.
    .PARAMETER Scopes
    One or more OAuth2 scopes to grant. Defaults to Mail.Send.
    .PARAMETER AuthMethod
    Authentication method to use. Valid values are 'Certificate', 'ClientSecret', 'ManagedIdentity', 'None'.
    .PARAMETER CertThumbprint
    Certificate thumbprint if using Certificate-based authentication.
    .PARAMETER CertStoreLocation
    The certificate store location (e.g., "Cert:\CurrentUser\My"). Defaults to 'Cert:\CurrentUser\My'.
    .EXAMPLE
    $appRegistration = Get-MgApplication -AppId "your-app-id"
    $requiredResourceAccessList = @()
    $context = [PSCustomObject]@{ TenantId = "your-tenant-id" }
    New-TkAppSpOauth2Registration -AppRegistration $appRegistration -RequiredResourceAccessList $requiredResourceAccessList -Context $context
    .NOTES
    This function requires the Microsoft.Graph PowerShell module.
#>

function New-TkAppSpOauth2Registration {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The App Registration object containing various properties.'
        )]
        [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphApplication]
        $AppRegistration,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The list of required resource access for the Service Principal.'
        )]
        [PSCustomObject[]]
        $RequiredResourceAccessList,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The Microsoft Graph context that we are currently in.'
        )]
        [PSCustomObject]
        $Context,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'One or more OAuth2 scopes to grant. Defaults to Mail.Send.'
        )]
        [psobject[]]
        $Scopes = [PSCustomObject]@{
            Graph = @('Mail.Send')
        },
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Authentication method to use. Valid values are "Certificate", "ClientSecret", "ManagedIdentity", "None".'
        )]
        [ValidateSet('Certificate', 'ClientSecret', 'ManagedIdentity', 'None')]
        [string]
        $AuthMethod = 'Certificate',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Certificate thumbprint if using Certificate-based authentication.'
        )]
        [string]
        $CertThumbprint,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The certificate store location (e.g., "Cert:\CurrentUser\My"). Defaults to "Cert:\CurrentUser\My".'
        )]
        [string]
        $CertStoreLocation = 'Cert:\CurrentUser\My'
    )
    begin {
        if (-not $script:LogString) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }
        Write-AuditLog '###############################################'
        if ($AuthMethod -eq 'Certificate' -and -not $CertThumbprint) {
            throw "CertThumbprint is required when AuthMethod is 'Certificate'."
        }

        $cert = $null
    }
    process {
        try {
            # 1. If using certificate auth, retrieve the certificate
            if ($AuthMethod -eq 'Certificate') {
                Write-AuditLog "Retrieving certificate with thumbprint $CertThumbprint."
                $cert = Get-ChildItem -Path $CertStoreLocation | Where-Object { $_.Thumbprint -eq $CertThumbprint }
                if (-not $cert) {
                    throw "Certificate with thumbprint $CertThumbprint not found in $CertStoreLocation."
                }
            }
            $shouldProcessTarget = "'$($AppRegistration.DisplayName)' for tenant $($Context.TenantId)."
            $shouldProcessOperation = 'New-MgServicePrincipal'
            if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
                # 2. Create a Service Principal for the app (if not existing).
                Write-AuditLog "Creating service principal for app with AppId $($AppRegistration.AppId)."
                [void](New-MgServicePrincipal -AppId $AppRegistration.AppId -AdditionalProperties @{})
            }
            # 3. Get the client Service Principal for the created app.
            $clientSp = Get-MgServicePrincipal -Filter "appId eq '$($AppRegistration.AppId)'"
            if (-not $clientSp) {
                Write-AuditLog "Client service principal not found for $($AppRegistration.AppId)." -Severity Error
                throw 'Unable to find client service principal.'
            }
            $shouldProcessTarget = "'$($clientSp.DisplayName)' requested scopes for tenant $($Context.TenantId)."
            $shouldProcessOperation = 'New-MgOauth2PermissionGrant'
            if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
                $i = 0
                foreach ($resource in $RequiredResourceAccessList) {
                    # 4. Combine all scopes into a single space-delimited string
                    switch ($i) {
                        0 {
                            $scopesList = $Scopes.Graph
                            $resourceId = (Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft Graph'").Id
                        }
                        1 {
                            $scopesList = $Scopes.SharePoint
                            $resourceId = (Get-MgServicePrincipal -Filter "DisplayName eq 'Office 365 SharePoint Online'").Id
                        }
                        2 {
                            $scopesList = $Scopes.Exchange
                            $resourceId = (Get-MgServicePrincipal -Filter "DisplayName eq 'Office 365 Exchange Online'").Id
                        }
                        ($i > 2) { throw 'Too many resources in RequiredResourceAccessList.' }
                        Default { Write-AuditLog "No scopes found for $resource." }
                    }
                    $combinedScopes = $scopesList -join ' '
                    # Foreach resource id start
                    Write-AuditLog "Granting the following scope(s) to Service Principal for: $($clientSp.DisplayName): $combinedScopes"
                    $mgOauth2PermissionGrantParams = @{
                        ClientId    = $clientSp.Id
                        ConsentType = 'AllPrincipals'
                        ResourceId  = $resourceId
                        Scope       = $combinedScopes
                    }
                    [void](New-MgOauth2PermissionGrant -BodyParameter $mgOauth2PermissionGrantParams -Confirm:$false -ErrorAction Stop)
                    Write-AuditLog "Admin consent granted for $resourceId with scopes: $combinedScopes."
                    Start-Sleep -Seconds 2
                    $i++
                }
            }
            $redirectUri = "&redirect_uri=https://login.microsoftonline.com/common/oauth2/nativeclient"
            # 5. Build the admin consent URL
            $adminConsentUrl = `
                'https://login.microsoftonline.com/' `
                + $Context.TenantId `
                + '/adminconsent?client_id=' `
                + $AppRegistration.AppId `
                + $redirectUri
            Write-Verbose 'Please go to the following URL in your browser to provide admin consent:' -Verbose
            Write-AuditLog "`n`n$adminConsentUrl`n" -Severity information -InformationAction Continue
            # For each end
            Write-Verbose 'After providing admin consent, you can use the following command for certificate-based auth:' -Verbose
            if ($AuthMethod -eq 'Certificate') {
                $connectGraph = 'Connect-MgGraph -ClientId "' + $AppRegistration.AppId + '" -TenantId "' +
                $Context.TenantId + '" -CertificateName "' + $cert.SubjectName.Name + '"'
                Write-AuditLog "`n`n$connectGraph`n" -Severity Information -InformationAction Continue
            }
            else {
                # Placeholder for other auth methods
                Write-AuditLog "Future logic for $AuthMethod auth can go here."
                throw "AuthMethod $AuthMethod is not yet implemented."
            }
            return $adminConsentUrl
        }
        catch {
            Write-AuditLog -Message "Error occurred: $($_.Exception.Message)" -Severity "Error"
            throw
        }
    }
    end {
        Write-AuditLog -EndFunction
    }
}
