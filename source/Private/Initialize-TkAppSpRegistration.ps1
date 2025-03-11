function Initialize-TkAppSpRegistration {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The App Registration object.'
        )]
        $AppRegistration,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The Graph Service Principal Id.'
        )]
        [PSCustomObject[]]$RequiredResourceAccessList,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The Azure context.'
        )]
        [PSCustomObject]$Context,
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
            HelpMessage = 'Auth method (placeholder). Currently only "Certificate" is used.'
        )]
        [ValidateSet('Certificate', 'ClientSecret', 'ManagedIdentity', 'None')]
        [string]$AuthMethod = 'Certificate',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Certificate thumbprint if using Certificate-based auth.'
        )]
        [string]$CertThumbprint,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The certificate store location (e.g., "Cert:\CurrentUser\My").'
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
    }
    process {
        try {
            # 1. If using certificate auth, retrieve the certificate
            $Cert = $null
            if ($AuthMethod -eq 'Certificate') {
                Write-AuditLog "Retrieving certificate with thumbprint $CertThumbprint."
                $Cert = Get-ChildItem -Path $CertStoreLocation | Where-Object { $_.Thumbprint -eq $CertThumbprint }
                if (-not $Cert) {
                    throw "Certificate with thumbprint $CertThumbprint not found in $CertStoreLocation."
                }
            }
            # 2. Create a Service Principal for the app (if not existing).
            Write-AuditLog "Creating service principal for app with AppId $($AppRegistration.AppId)."
            [void](New-MgServicePrincipal -AppId $AppRegistration.AppId -AdditionalProperties @{})
            # 3. Get the client Service Principal for the created app.
            $ClientSp = Get-MgServicePrincipal -Filter "appId eq '$($AppRegistration.AppId)'"
            if (-not $ClientSp) {
                Write-AuditLog "Client service principal not found for $($AppRegistration.AppId)." -Severity Error
                throw 'Unable to find client service principal.'
            }
            $i = 0
            foreach ($Resource in $RequiredResourceAccessList) {
                # 4. Combine all scopes into a single space-delimited string
                switch ($i) {
                    0 { $ScopesList = $Scopes.Graph
                        $ResourceId = (Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft Graph'").Id
                    }
                    1 { $ScopesList = $Scopes.SharePoint
                        $ResourceId = (Get-MgServicePrincipal -Filter "DisplayName eq 'Office 365 SharePoint Online'").Id
                    }
                    2 { $ScopesList = $Scopes.Exchange
                        $ResourceId = (Get-MgServicePrincipal -Filter "DisplayName eq 'Office 365 Exchange Online'").Id
                    }
                    ($i > 2) { throw 'Too many resources in RequiredResourceAccessList.' }
                    Default { Write-AuditLog "No scopes found for $Resource." }
                }
                $combinedScopes = $ScopesList -join ' '
                # Foreach resource id start
                Write-AuditLog "Granting the following scope(s) to Service Principal $($ClientSp.DisplayName): $combinedScopes"
                $Params = @{
                    ClientId    = $ClientSp.Id
                    ConsentType = 'AllPrincipals'
                    ResourceId  = $ResourceId
                    Scope       = $combinedScopes
                }
                [void](New-MgOauth2PermissionGrant -BodyParameter $Params -Confirm:$false -ErrorAction Stop)
                Write-AuditLog "Admin consent granted for $ResourceId with scopes: $combinedScopes."
                Start-Sleep -Seconds 2
                $i++
            }
                # 5. Build the admin consent URL
                $adminConsentUrl = 'https://login.microsoftonline.com/' + $Context.TenantId + '/adminconsent?client_id=' + $AppRegistration.AppId
                Write-Verbose 'Please go to the following URL in your browser to provide admin consent:' -Verbose
                Write-AuditLog  "`n$adminConsentUrl`n" -Severity information
            # For each end
            Write-Verbose 'After providing admin consent, you can use the following command for certificate-based auth:' -Verbose
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
