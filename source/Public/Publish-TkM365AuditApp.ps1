<#
    .SYNOPSIS
        Publishes (creates) a new M365 Audit App registration in Entra ID (Azure AD) with a specified certificate.
    .DESCRIPTION
        The Publish-TkM365AuditApp function creates a new Azure AD application used for M365 auditing.
        It connects to Microsoft Graph, gathers the required permissions for SharePoint and Exchange,
        and optionally creates a self-signed certificate if no thumbprint is provided. It also assigns
        the application to the Exchange Administrator and Global Reader roles. By default, the newly
        created application details are stored as a secret in the specified SecretManagement vault.
    .PARAMETER AppPrefix
        A short prefix (2-4 alphanumeric characters) used to build the app name. Defaults to "Gtk"
        if not specified.
    .PARAMETER CertThumbprint
        The thumbprint of an existing certificate in the current user's certificate store. If not
        provided, a new self-signed certificate is created.
    .PARAMETER KeyExportPolicy
        Specifies whether the newly created certificate (if no thumbprint is provided) is
        'Exportable' or 'NonExportable'. Defaults to 'NonExportable'.
    .PARAMETER VaultName
        The SecretManagement vault name in which to store the app credentials. Defaults to
        "M365AuditAppLocalStore" if not specified.
    .PARAMETER OverwriteVaultSecret
        If specified, overwrites an existing secret in the specified vault if it already exists.
    .PARAMETER ReturnParamSplat
        If specified, returns a parameter splat string for use in other functions, instead of the
        default PSCustomObject containing the app details.
    .EXAMPLE
        PS C:\> Publish-TkM365AuditApp -AppPrefix "CS12" -ReturnParamSplat
        Creates a new M365 Audit App with the prefix "CS12", returns a parameter splat, and stores
        the credentials in the default vault.
    .INPUTS
        None. This function does not accept pipeline input.
    .OUTPUTS
        By default, returns a PSCustomObject with details of the new app (AppId, ObjectId, TenantId,
        certificate thumbprint, expiration, etc.). If -ReturnParamSplat is used, returns a parameter
        splat string.
    .NOTES
        Requires the Microsoft.Graph and ExchangeOnlineManagement modules for app creation and
        role assignment. The user must have sufficient privileges to create and manage applications
        in Azure AD, and to assign roles. After creation, admin consent may be required for the
        assigned permissions.
        Permissions required:
            'Application.ReadWrite.All',
            'DelegatedPermissionGrant.ReadWrite.All',
            'Directory.ReadWrite.All',
            'RoleManagement.ReadWrite.Directory'
#>
function Publish-TkM365AuditApp {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'Prefix for the new M365 Audit app name (2-4 alphanumeric characters).'
        )]
        [ValidatePattern('^[A-Z0-9]{2,4}$')]
        [string]
        $AppPrefix = 'Gtk',
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'Thumbprint of an existing certificate to use. If not provided, a self-signed cert will be created.'
        )]
        [ValidatePattern('^[A-Fa-f0-9]{40}$')]
        [string]
        $CertThumbprint,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Key export policy for the certificate.'
        )]
        [ValidateSet('Exportable', 'NonExportable')]
        [string]
        $KeyExportPolicy = 'NonExportable',
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'Name of the SecretManagement vault to store app credentials.'
        )]
        [string]
        $VaultName = 'M365AuditAppLocalStore',
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'If specified, overwrite the vault secret if it already exists.'
        )]
        [switch]
        $OverwriteVaultSecret,
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'Return output as a parameter splat string for use in other functions.'
        )]
        [switch]$ReturnParamSplat
    )
    begin {
        if (-not $script:LogString) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }
        Write-AuditLog '###############################################'
        Write-AuditLog 'Initializing M365 Audit App publication process...'
        $scopesNeeded = @(
            'Application.ReadWrite.All',
            'DelegatedPermissionGrant.ReadWrite.All',
            'Directory.ReadWrite.All',
            'RoleManagement.ReadWrite.Directory'
        )
        # 1) Connect to Graph so we can query permissions & create the app
        Connect-TkMsService -MgGraph -GraphAuthScopes $scopesNeeded
    }
    process {
        try {
            # 2) Define read-only vs. read-write sets
            $graph = @(
                'AppCatalog.ReadWrite.All',
                'Channel.Delete.All',
                'ChannelMember.ReadWrite.All',
                'ChannelSettings.ReadWrite.All',
                'Directory.Read.All',
                'Group.ReadWrite.All',
                'Organization.Read.All',
                'Policy.Read.All',
                'Domain.Read.All'
                'TeamSettings.ReadWrite.All'
                'User.Read.All'
            )
            $sharePoint = @('Sites.Read.All', 'Sites.FullControl.All')
            $exchange = @('Exchange.ManageAsApp')
            # Decide which sets to use
            $graphPerms = $graph
            $sharePointPerms = $sharePoint
            $exchangePerms = $exchange
            $permissionsObject = [PSCustomObject]@{
                Graph      = $graphPerms
                SharePoint = $sharePointPerms
                Exchange   = $exchangePerms
            }
            Write-AuditLog "Graph Perms: $($graphPerms -join ', ')"
            Write-AuditLog "SharePoint Perms: $($sharePointPerms -join ', ')"
            Write-AuditLog "Exchange Perms: $($exchangePerms -join ', ')"
            $Context = Get-MgContext -ErrorAction Stop
            # Gather the resource access objects (GUIDs) for all these perms
            $AppSettings = New-TkRequiredResourcePermissionObject `
                -GraphPermissions $graphPerms `
                -Scenario '365Audit' `
                -ErrorAction Stop
            # Generate the app name
            $appName = New-TkAppName `
                -Prefix $AppPrefix `
                -ScenarioName 'M365Audit' `
                -ErrorAction Stop
            Write-AuditLog "Proposed new M365 Audit App name: $appName"
            # Retrieve or create the certificate
            $CertDetails = Initialize-TkAppAuthCertificate `
                -AppName $appName `
                -Thumbprint $CertThumbprint `
                -Subject "CN=$appName" `
                -KeyExportPolicy $KeyExportPolicy `
                -ErrorAction Stop
            Write-AuditLog "Certificate Thumbprint: $($CertDetails.CertThumbprint); Expires: $($CertDetails.CertExpires)."
            # Show user proposed config
            $proposed = [PSCustomObject]@{
                ProposedAppName       = $appName
                CertificateThumbprint = $CertDetails.CertThumbprint
                CertExpires           = $CertDetails.CertExpires
                GraphPermissions      = $graphPerms -join ', '
                SharePointPermissions = $sharePointPerms -join ', '
                ExchangePermissions   = $exchangePerms -join ', '
            }
            Write-AuditLog 'Proposed creation of a new M365 Audit App with the following properties:'
            Write-AuditLog "$($proposed | Format-List)"
            # Create the app in one pass with all resources
            $notesHash = [ordered]@{
                'Certificate Thumbprint'   = $($CertDetails.CertThumbprint)
                'Certificate Expires'      = $($CertDetails.CertExpires)
                'GraphAppPermissions'      = $($graphPerms -join ', ')
                'SharePointAppPermissions' = $($sharePointPerms -join ', ')
                'ExchangeAppPermissions'   = $($exchangePerms -join ', ')
                'RolesAssigned'            = @('Exchange Administrator', 'Global Reader')
                'AuthorizedClient IP'      = $((Invoke-RestMethod ifconfig.me/ip))
                'ClientOrUserHostname'     = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { $env:USERNAME }
            }
            # Convert that hashtable to a JSON string:
            $Notes = $notesHash | ConvertTo-Json #-Compress
            if ($PSCmdlet.ShouldProcess($appName, 'Create and configure M365 Audit App in EntraAD')) {
                Write-AuditLog 'Creating new EntraAD application with all resource permissions...'
                $appRegistration = New-TkAppRegistration `
                    -DisplayName $appName `
                    -CertThumbprint $CertDetails.CertThumbprint `
                    -RequiredResourceAccessList $AppSettings.RequiredResourceAccessList `
                    -Notes $Notes `
                    -SignInAudience 'AzureADMyOrg' `
                    -ErrorAction Stop
                Write-AuditLog "App registered. Object ID = $($appRegistration.Id), ClientId = $($appRegistration.AppId)."
                # Grant the oauth2 permissions to service principal
                $ConsentUrl = Initialize-TkAppSpRegistration `
                    -AppRegistration $appRegistration `
                    -Context $Context `
                    -RequiredResourceAccessList $AppSettings.RequiredResourceAccessList `
                    -Scopes $permissionsObject `
                    -AuthMethod 'Certificate' `
                    -CertThumbprint $CertDetails.CertThumbprint `
                    -ErrorAction Stop
                [void](Read-Host 'Provide admin consent now, or copy the url and provide admin consent later. Press Enter to continue.')
                Write-AuditLog 'Appending Exchange Administrator role to the app.'
                $exoAdminRole = Get-MgDirectoryRole -Filter "displayName eq 'Exchange Administrator'" -ErrorAction Stop
                # Get the service principal object ID of the app
                $sp = Get-MgServicePrincipal -Filter "appId eq '$($appRegistration.appid)'" -ErrorAction Stop
                $spObjectId = $sp.Id
                $body = @{
                    '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$spObjectId"
                }
                New-MgDirectoryRoleMemberByRef `
                    -DirectoryRoleId $exoAdminRole.Id `
                    -BodyParameter $body `
                    -ErrorAction Stop
                Write-AuditLog 'Appending Global Reader role to the app.'
                $globalReaderRole = Get-MgDirectoryRole `
                    -Filter "displayName eq 'Global Reader'" `
                    -ErrorAction Stop
                New-MgDirectoryRoleMemberByRef `
                    -DirectoryRoleId $globalReaderRole.Id `
                    -BodyParameter $body `
                    -ErrorAction Stop
                # Store final app info in the vault
                $output = [PSCustomObject]@{
                    AppName               = $("CN=$appName")
                    AppId                 = $appRegistration.AppId
                    ObjectId              = $appRegistration.Id
                    TenantId              = $context.TenantId
                    CertThumbprint        = $CertDetails.CertThumbprint
                    CertExpires           = $CertDetails.CertExpires
                    ConsentUrl            = $ConsentUrl
                    MgGraphPermissions    = "$($graphPerms)"
                    SharePointPermissions = "$($sharePointPerms)"
                    ExchangePermissions   = "$($exchangePerms)"
                }
                $m365AuditApp = [TkM365AuditAppParams]::new(
                    $output.AppName,
                    $output.AppId,
                    $output.ObjectId,
                    $output.TenantId,
                    $output.CertThumbprint,
                    $output.CertExpires,
                    $output.ConsentUrl,
                    $output.MgGraphPermissions,
                    $output.SharePointPermissions,
                    $output.ExchangePermissions
                )
                # Save to vault
                Set-TkJsonSecret `
                    -Name "CN=$appName" `
                    -InputObject $output `
                    -VaultName $VaultName `
                    -Overwrite:$OverwriteVaultSecret
                Write-AuditLog "Saved app credentials to vault '$VaultName'."
                # Return as either param splat or plain object
                if ($ReturnParamSplat) {
                    return $m365AuditApp | ConvertTo-ParameterSplat
                }
                else {
                    return $m365AuditApp
                }
            }
        }
        catch {
            throw
        }
        finally {
            Write-AuditLog -EndFunction
        }
    }
}
