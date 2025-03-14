<#
    .SYNOPSIS
    Initializes the Service Principal registration for a given application.
    .DESCRIPTION
    This function sets up the Service Principal registration for an application in Azure AD. It supports certificate-based authentication and grants OAuth2 permissions to the Service Principal.
    .PARAMETER AppRegistration
    The App Registration object for various properties.
    .PARAMETER RequiredResourceAccessList
    The Graph Service Principal Id.
    .PARAMETER Context
    The Microsoft Graph context that we are currently in.
    .PARAMETER Scopes
    One or more OAuth2 scopes to grant. Defaults to Mail.Send.
    .PARAMETER AuthMethod
    Auth method (placeholder). Currently only "Certificate" is used. Valid values are 'Certificate', 'ClientSecret', 'ManagedIdentity', 'None'.
    .PARAMETER CertThumbprint
    Certificate thumbprint if using Certificate-based auth.
    .PARAMETER CertStoreLocation
    The certificate store location (e.g., "Cert:\CurrentUser\My"). Defaults to 'Cert:\CurrentUser\My'.
    .EXAMPLE
    $AppRegistration = Get-MgApplication -AppId "your-app-id"
    $RequiredResourceAccessList = @()
    $Context = [PSCustomObject]@{ TenantId = "your-tenant-id" }
    Initialize-TkAppSpRegistration -AppRegistration $AppRegistration -RequiredResourceAccessList $RequiredResourceAccessList -Context $Context
    .NOTES
    This function requires the Microsoft.Graph PowerShell module.
#>

function Initialize-TkAppSpRegistration {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = `
                'The App Registration object.'
        )]
        [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphApplication]
        $AppRegistration,
        [Parameter(
            Mandatory = $true,
            HelpMessage = `
                'The Graph Service Principal Id.'
        )]
        [PSCustomObject[]]
        $RequiredResourceAccessList,
        [Parameter(
            Mandatory = $true,
            HelpMessage = `
                'The Azure context.'
        )]
        [PSCustomObject]
        $Context,
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'One or more OAuth2 scopes to grant. Defaults to Mail.Send.'
        )]
        [psobject[]]
        $Scopes = [PSCustomObject]@{
            Graph = @('Mail.Send')
        },
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'Auth method (placeholder). Currently only "Certificate" is used.'
        )]
        [ValidateSet('Certificate', 'ClientSecret', 'ManagedIdentity', 'None')]
        [string]
        $AuthMethod = 'Certificate',
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'Certificate thumbprint if using Certificate-based auth.'
        )]
        [string]
        $CertThumbprint,
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'The certificate store location (e.g., "Cert:\CurrentUser\My").'
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

        $Cert = $null
    }
    process {
        try {
            # 1. If using certificate auth, retrieve the certificate
            if ($AuthMethod -eq 'Certificate') {
                Write-AuditLog "Retrieving certificate with thumbprint $CertThumbprint."
                $Cert = Get-ChildItem -Path $CertStoreLocation | Where-Object { $_.Thumbprint -eq $CertThumbprint }
                if (-not $Cert) {
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
            $ClientSp = Get-MgServicePrincipal -Filter "appId eq '$($AppRegistration.AppId)'"
            if (-not $ClientSp) {
                Write-AuditLog "Client service principal not found for $($AppRegistration.AppId)." -Severity Error
                throw 'Unable to find client service principal.'
            }
            $shouldProcessTarget = "'$($ClientSp.DisplayName)' requested scopes for tenant $($Context.TenantId)."
            $shouldProcessOperation = 'New-MgOauth2PermissionGrant'
            if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
                $i = 0
                foreach ($Resource in $RequiredResourceAccessList) {
                    # 4. Combine all scopes into a single space-delimited string
                    switch ($i) {
                        0 {
                            $ScopesList = $Scopes.Graph
                            $ResourceId = (Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft Graph'").Id
                        }
                        1 {
                            $ScopesList = $Scopes.SharePoint
                            $ResourceId = (Get-MgServicePrincipal -Filter "DisplayName eq 'Office 365 SharePoint Online'").Id
                        }
                        2 {
                            $ScopesList = $Scopes.Exchange
                            $ResourceId = (Get-MgServicePrincipal -Filter "DisplayName eq 'Office 365 Exchange Online'").Id
                        }
                        ($i > 2) { throw 'Too many resources in RequiredResourceAccessList.' }
                        Default { Write-AuditLog "No scopes found for $Resource." }
                    }
                    $combinedScopes = $ScopesList -join ' '
                    # Foreach resource id start
                    Write-AuditLog "Granting the following scope(s) to Service Principal for: $($ClientSp.DisplayName): $combinedScopes"
                    $MgOauth2PermissionGrantParams = @{
                        ClientId    = $ClientSp.Id
                        ConsentType = 'AllPrincipals'
                        ResourceId  = $ResourceId
                        Scope       = $combinedScopes
                    }
                    [void](New-MgOauth2PermissionGrant -BodyParameter $MgOauth2PermissionGrantParams -Confirm:$false -ErrorAction Stop)
                    Write-AuditLog "Admin consent granted for $ResourceId with scopes: $combinedScopes."
                    Start-Sleep -Seconds 2
                    $i++
                }
            }
            # 5. Build the admin consent URL
            $adminConsentUrl = `
                'https://login.microsoftonline.com/' `
                + $Context.TenantId `
                + '/adminconsent?client_id=' `
                + $AppRegistration.AppId
            Write-Verbose 'Please go to the following URL in your browser to provide admin consent:`n' -Verbose
            Write-AuditLog "`n$adminConsentUrl`n" -Severity information
            # For each end
            Write-Verbose 'After providing admin consent, you can use the following command for certificate-based auth:`n' -Verbose
            if ($AuthMethod -eq 'Certificate') {
                $connectGraph = 'Connect-MgGraph -ClientId "' + $AppRegistration.AppId + '" -TenantId "' +
                $Context.TenantId + '" -CertificateName "' + $Cert.SubjectName.Name + '"'
                Write-AuditLog "`n$connectGraph`n" -Severity Information
            }
            else {
                # Placeholder for other auth methods
                Write-AuditLog "Future logic for $AuthMethod auth can go here."
                throw "AuthMethod $AuthMethod is not yet implemented."
            }
            return $adminConsentUrl
        }
        catch {
            throw
        }
    }
    end {
        Write-AuditLog -EndFunction
    }
}
