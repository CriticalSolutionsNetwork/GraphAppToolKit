<#
    .SYNOPSIS
        Publishes a new MEM (Intune) Policy Manager App in Azure AD with read-only or read-write permissions.
    .DESCRIPTION
        The Publish-TkMemPolicyManagerApp function creates an Azure AD application intended for managing
        Microsoft Endpoint Manager (MEM/Intune) policies. It optionally creates or retrieves a certificate,
        configures the necessary Microsoft Graph permissions for read-only or read-write access, and stores
        the resulting app credentials in a SecretManagement vault.
    .PARAMETER AppPrefix
        A 2-4 character prefix used to build the application name (e.g., CORP, MSN). This helps uniquely
        identify the app in Azure AD.
    .PARAMETER CertThumbprint
        The thumbprint of an existing certificate in the current user's certificate store. If omitted,
        a new self-signed certificate is created.
    .PARAMETER KeyExportPolicy
        Specifies whether the newly created certificate is 'Exportable' or 'NonExportable'.
        Defaults to 'NonExportable' if not specified.
    .PARAMETER VaultName
        The name of the SecretManagement vault in which to store the app credentials.
        Defaults to 'MemPolicyManagerLocalStore'.
    .PARAMETER OverwriteVaultSecret
        If specified, overwrites any existing secret of the same name in the vault.
    .PARAMETER ReadWrite
        If specified, grants read-write MEM/Intune permissions. Otherwise, read-only permissions are granted.
    .PARAMETER ReturnParamSplat
        If specified, returns a parameter splat string for use in other functions. Otherwise, returns
        a PSCustomObject containing the app details.
    .PARAMETER DoNotUseDomainSuffix
        If specified, the function does not append the domain suffix to the app name.
    .EXAMPLE
        PS C:\> Publish-TkMemPolicyManagerApp -AppPrefix "CORP" -ReadWrite
        Creates a new MEM Policy Manager App with read-write permissions, retrieves or
        creates a certificate, and stores the credentials in the default vault.
    .INPUTS
        None. This function does not accept pipeline input.
    .OUTPUTS
        By default, returns a PSCustomObject (TkMemPolicyManagerAppParams) with details of the newly created
        app (AppId, certificate thumbprint, tenant ID, etc.). If -ReturnParamSplat is used, returns a parameter
        splat string.
    .NOTES
        This function requires the Microsoft.Graph module for application creation and the user must have
        permissions in Azure AD to register and grant permissions to the application. After creation, admin
        consent may be needed to finalize the permission grants.
        Permissions required:
            'Application.ReadWrite.All',
            'DelegatedPermissionGrant.ReadWrite.All',
            'Directory.ReadWrite.All',
            'RoleManagement.ReadWrite.Directory'
#>
function Publish-TkMemPolicyManagerApp {
    [CmdletBinding(ConfirmImpact = 'High')]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = `
                '2-4 character prefix used for the App Name (e.g. MSN, CORP, etc.)'
        )]
        [ValidatePattern('^[A-Z0-9]{2,4}$')]
        [string]
        $AppPrefix,
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'Thumbprint of the certificate. If omitted, a self-signed cert is created.'
        )]
        [ValidatePattern('^[A-Fa-f0-9]{40}$')]
        [string]
        $CertThumbprint,
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'Key export policy for the certificate.'
        )]
        [ValidateSet('Exportable', 'NonExportable')]
        [string]
        $KeyExportPolicy = 'NonExportable',
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'If specified, use a custom vault name. Otherwise, use the default.'
        )]
        [string]
        $VaultName = 'MemPolicyManagerLocalStore',
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'If specified, overwrite the vault secret if it already exists.'
        )]
        [switch]
        $OverwriteVaultSecret,
        [Parameter(
            HelpMessage = `
                'If specified, grant ReadWrite perms. Otherwise, read-only perms.'
        )]
        [switch]
        $ReadWrite,
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'Return the param splat for use in other functions.'
        )]
        [switch]$ReturnParamSplat,
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'If specified, do not append the domain suffix to the app name.'
        )]
        [switch]
        $DoNotUseDomainSuffix
    )
    begin {
        if (-not $script:LogString) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }
        try {
            Write-AuditLog '###############################################'
            $PublicMods = 'Microsoft.Graph', 'Microsoft.PowerShell.SecretManagement', 'SecretManagement.JustinGrote.CredMan'
            $PublicVers = '1.22.0', '1.1.2', '1.0.0'
            $ImportMods = 'Microsoft.Graph.Authentication', 'Microsoft.Graph.Applications', 'Microsoft.Graph.Identity.SignIns', 'Microsoft.Graph.Users'
            $ModParams = @{
                PublicModuleNames      = $PublicMods
                PublicRequiredVersions = $PublicVers
                ImportModuleNames      = $ImportMods
                Scope                  = 'CurrentUser'
            }
            Initialize-TkModuleEnv @ModParams
            # Only connect to Graph
            $scopesNeeded = @(
                'Application.ReadWrite.All',
                'DelegatedPermissionGrant.ReadWrite.All',
                'Directory.ReadWrite.All'
            )
            Connect-TkMsService `
                -MgGraph `
                -GraphAuthScopes $scopesNeeded `
                -ErrorAction Stop
            $Context = Get-MgContext -ErrorAction Stop
        }
        catch {
            throw
        }
    }
    process {
        try {
            # 1) Determine the correct set of MEM permissions
            $readWritePerms = @(
                'DeviceManagementConfiguration.ReadWrite.All',
                'DeviceManagementApps.ReadWrite.All',
                'DeviceManagementManagedDevices.ReadWrite.All',
                'Policy.ReadWrite.ConditionalAccess',
                'Policy.Read.All'
            )
            $readOnlyPerms = @(
                'DeviceManagementConfiguration.Read.All',
                'DeviceManagementApps.Read.All',
                'DeviceManagementManagedDevices.Read.All',
                'Policy.Read.ConditionalAccess',
                'Policy.Read.All'
            )
            $permissions = if ($ReadWrite) { $readWritePerms } else { $readOnlyPerms }
            $permissionsObject = [PSCustomObject]@{
                Graph = $permissions
            }
            Write-AuditLog "Using the following MEM permissions: $($permissions -join ', ')"
            # 2) Build a Graph context object that looks up these permission IDs
            $AppSettings = Initialize-TkRequiredResourcePermissionObject `
                -GraphPermissions $permissions
            # 3) Build an app name for scenario "MemPolicyManager"
            $appName = Initialize-TkAppName `
                -Prefix $AppPrefix `
                -ScenarioName 'MemPolicyManager' `
                -DoNotUseDomainSuffix:$DoNotUseDomainSuffix `
                -ErrorAction Stop
            # 4) Add TenantId & AppName to the object so we can store them in the final JSON
            $AppSettings | Add-Member -NotePropertyName 'TenantId' -NotePropertyValue $Context.TenantId
            $AppSettings | Add-Member -NotePropertyName 'AppName' -NotePropertyValue $appName
            # 5) Create or retrieve the certificate
            $AppAuthCertificateParams = @{
                AppName         = $AppSettings.AppName
                Thumbprint      = $CertThumbprint
                Subject         = "CN=$($AppSettings.AppName)"
                KeyExportPolicy = $KeyExportPolicy
                ErrorAction     = 'Stop'
            }
            $CertDetails = Initialize-TkAppAuthCertificate @AppAuthCertificateParams
            # Build a “proposed” object so the user sees what’s about to happen
            $proposedObject = [PSCustomObject]@{
                ProposedAppName           = $AppSettings.AppName
                CertificateThumbprintUsed = $CertDetails.CertThumbprint
                CertificateExpires        = $CertDetails.CertExpires
                TenantID                  = $Context.TenantId
                RequestedPermissions      = ($permissions -join ', ')
                PermissionType            = 'Application'
            }
            Write-AuditLog 'Proposed creation of a new MEM Policy Manager App with the following properties:'
            Write-AuditLog "$($proposedObject | Format-List)"
            $notesHash = [ordered]@{
                'Certificate Thumbprint' = $($CertDetails.CertThumbprint)
                'Certificate Expires'    = $($CertDetails.CertExpires)
                'GraphAppPermissions'    = $($permissions -join ', ')
                'Read-Write Permissions' = $(if ($ReadWrite) { 'ReadWrite' } else { 'Read-Only' })
                'AuthorizedClient IP'    = $((Invoke-RestMethod ifconfig.me/ip))
                'ClientOrUserHostname'   = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { $env:USERNAME }
            }
            # Convert that hashtable to a JSON string:
            $Notes = $notesHash | ConvertTo-Json #-Compress
            # 6) Register the application (with the cert)
            $AppRegistrationParams = @{
                DisplayName                = $AppSettings.AppName
                CertThumbprint             = $CertDetails.CertThumbprint
                RequiredResourceAccessList = $AppSettings.RequiredResourceAccessList
                SignInAudience             = 'AzureADMyOrg'
                Notes                      = $Notes
                ErrorAction                = 'Stop'
            }
            $appRegistration = New-TkAppRegistration @AppRegistrationParams
            # 7) Create the Service Principal & grant the permissions
            $AppSpRegistrationParams = @{
                AppRegistration            = $appRegistration
                Context                    = $Context
                RequiredResourceAccessList = $AppSettings.RequiredResourceAccessList
                Scopes                     = $permissionsObject
                AuthMethod                 = 'Certificate'
                CertThumbprint             = $CertDetails.CertThumbprint
                ErrorAction                = 'Stop'
            }
            $ConsentUrl = Initialize-TkAppSpRegistration @AppSpRegistrationParams
            [void](Read-Host 'Provide admin consent now, or copy the url and provide admin consent later. Press Enter to continue.')
            # 8) Build a final PSCustomObject to store in the secret vault
            $TkMemPolicyManagerAppParams = @{
                AppId          = $appRegistration.AppId
                AppName        = "CN=$($AppSettings.AppName)"
                CertThumbprint = $CertDetails.CertThumbprint
                ObjectId       = $appRegistration.Id
                ConsentUrl     = $ConsentUrl
                PermissionSet  = if ($ReadWrite) { 'ReadWrite' } else { 'ReadOnly' }
                Permissions    = $permissions
                TenantId       = $Context.TenantId
            }
            [TkMemPolicyManagerAppParams]$AppParamsObject = Initialize-TkMemPolicyManagerAppParamsObject @TkMemPolicyManagerAppParams
            # 9) Store as JSON secret
            $JsonSecretParams = @{
                Name        = "CN=$($AppSettings.AppName)"
                InputObject = $AppParamsObject
                VaultName   = $VaultName
                Overwrite   = $OverwriteVaultSecret
                ErrorAction = 'Stop'
            }
            $savedName = Set-TkJsonSecret @JsonSecretParams
            Write-AuditLog "Secret '$savedName' saved to vault '$VaultName'."
            # Return the final object (param-splat or normal)
            if ($ReturnParamSplat) {
                return $AppParamsObject | ConvertTo-ParameterSplat
            }
            else {
                return $AppParamsObject
            }
        }
        catch {
            throw
        }
    }
    end {
        Write-AuditLog -EndFunction
    }
}