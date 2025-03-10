<#
    .SYNOPSIS
        Deploys a new Microsoft Graph Email app and associates it with a certificate for app-only authentication.
    .DESCRIPTION
        This cmdlet deploys a new Microsoft Graph Email app and associates it with a certificate for
        app-only authentication. It requires an AppPrefix for the app, an optional CertThumbprint, an
        AuthorizedSenderUserName, and a MailEnabledSendingGroup. Additionally, you can specify a
        KeyExportPolicy for the certificate, control how secrets are stored via VaultName and OverwriteVaultSecret,
        and optionally return a parameter splat instead of a PSCustomObject.
    .PARAMETER AppPrefix
        A unique prefix for the Graph Email App to initialize. Ensure it is used consistently for
        grouping purposes (2-4 alphanumeric characters).
    .PARAMETER CertThumbprint
        An optional parameter indicating the thumbprint of the certificate to be retrieved. If not
        specified, a self-signed certificate will be generated.
    .PARAMETER KeyExportPolicy
        Specifies the key export policy for the newly created certificate. Valid values are
        'Exportable' or 'NonExportable'. Defaults to 'NonExportable'.
    .PARAMETER AuthorizedSenderUserName
        The username of the authorized sender.
    .PARAMETER MailEnabledSendingGroup
        The mail-enabled group to which the sender belongs. This will be used to assign
        app policy restrictions.
    .PARAMETER VaultName
        If specified, the name of the vault to store the app's credentials. Otherwise,
        defaults to 'GraphEmailAppLocalStore'.
    .PARAMETER OverwriteVaultSecret
        If specified, the function overwrites an existing secret in the vault if it
        already exists.
    .PARAMETER ReturnParamSplat
        If specified, returns the parameter splat for use in other functions instead
        of the PSCustomObject.
    .EXAMPLE
        PS C:\> Publish-TkEmailApp -AppPrefix "ABC" -AuthorizedSenderUserName "jdoe@example.com" -MailEnabledSendingGroup "GraphAPIMailGroup@example.com" -CertThumbprint "AABBCCDDEEFF11223344556677889900"
    .INPUTS
        None
    .OUTPUTS
        By default, returns a PSCustomObject containing details such as AppId, CertThumbprint,
        TenantID, and CertExpires. If -ReturnParamSplat is specified, returns the parameter
        splat instead.
    .NOTES
        This cmdlet requires that the user running the cmdlet have the necessary permissions to
        create the app and connect to Exchange Online. In addition, a mail-enabled security group
        must already exist in Exchange Online for the MailEnabledSendingGroup parameter.

        Permissions required:
            'Application.ReadWrite.All',
            'DelegatedPermissionGrant.ReadWrite.All',
            'Directory.ReadWrite.All',
            'RoleManagement.ReadWrite.Directory'
#>

function Publish-TkEmailApp {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The prefix used to initialize the Graph Email App. 2-4 characters letters and numbers only.'
        )]
        [ValidatePattern('^[A-Z0-9]{2,4}$')]
        [string]
        $AppPrefix,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The thumbprint of the certificate to be retrieved.'
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
            Mandatory = $true,
            HelpMessage = 'The username of the authorized sender.'
        )]
        [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')]
        [string]
        $AuthorizedSenderUserName,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The Mail Enabled Sending Group.'
        )]
        [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')]
        [string]
        $MailEnabledSendingGroup,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'If specified, use a custom vault name. Otherwise, use the default.'
        )]
        [string]
        $VaultName = 'GraphEmailAppLocalStore',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'If specified, overwrite the vault secret if it already exists.'
        )]
        [switch]
        $OverwriteVaultSecret,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Return the parameter splat for use in other functions.'
        )]
        [switch]
        $ReturnParamSplat
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
            # 1) Ensure required modules are installed
            $PublicMods = 'Microsoft.Graph', 'ExchangeOnlineManagement', 'Microsoft.PowerShell.SecretManagement', 'SecretManagement.JustinGrote.CredMan'
            $PublicVers = '1.22.0', '3.1.0', '1.1.2', '1.0.0'
            $ImportMods = 'Microsoft.Graph.Authentication', 'Microsoft.Graph.Applications', 'Microsoft.Graph.Identity.SignIns', 'Microsoft.Graph.Users'
            $ModParams = @{
                PublicModuleNames      = $PublicMods
                PublicRequiredVersions = $PublicVers
                ImportModuleNames      = $ImportMods
                Scope                  = 'CurrentUser'
            }
            Initialize-TkModuleEnv @ModParams
            # 2) Connect to both Graph and Exchange
            Connect-TkMsService -MgGraph -ExchangeOnline
            # 3) Verify if the user (authorized sender) exists
            $user = Get-MgUser -Filter "Mail eq '$AuthorizedSenderUserName'"
            if (-not $user) {
                throw "User '$AuthorizedSenderUserName' not found in the tenant."
            }
            $Context = Get-MgContext -ErrorAction Stop
            # 4) Build the app context (Mail.Send permission, etc.)
            $AppSettings = New-TkRequiredResourcePermissionObject -GraphPermissions 'Mail.Send'
            $appName = New-TkAppName `
                -Prefix $AppPrefix `
                -ScenarioName 'AuditGraphEmail' `
                -UserId $AuthorizedSenderUserName
            # Add relevant properties to $AppSettings
            $AppSettings | Add-Member -NotePropertyName 'User' -NotePropertyValue $user
            $AppSettings | Add-Member -NotePropertyName 'AppName' -NotePropertyValue $appName
            # 5) Create or retrieve the certificate
            $CertDetails = Initialize-TkAppAuthCertificate `
                -AppName $AppSettings.AppName `
                -Thumbprint $CertThumbprint `
                -Subject "CN=$($AppSettings.AppName)" `
                -KeyExportPolicy $KeyExportPolicy `
                -ErrorAction Stop
        }
        catch {
            throw
        }
    }
    process {
        $proposedObject = [PSCustomObject]@{
            ProposedAppName                 = $AppSettings.AppName
            CertificateThumbprintUsed       = $CertDetails.CertThumbprint
            CertExpires                     = $CertDetails.CertExpires
            UserPrincipalName               = $user.UserPrincipalName
            TenantID                        = $Context.TenantId
            Permissions                     = 'Mail.Send'
            PermissionType                  = 'Application'
            ConsentType                     = 'AllPrincipals'
            ExchangePolicyRestrictedToGroup = $MailEnabledSendingGroup
        }
        Write-AuditLog 'The following object will be created (or configured) in Azure AD:'
        Write-AuditLog "`n$($proposedObject | Format-List)`n"
        $permissionsObject = [PSCustomObject]@{
            Graph = 'Mail.Send'
        }
        if ($PSCmdlet.ShouldProcess(
                "GraphEmailApp '$($AppSettings.AppName)'",
                'Creating & configuring a new Graph Email App in Azure AD'
            )) {
            try {
                $Notes = @"
Graph Email App for: $AuthorizedSenderUserName
Restricted to group: '$MailEnabledSendingGroup'.
Certificate Thumbprint: $($CertDetails.CertThumbprint)
Certificate Expires: $($CertDetails.CertExpires)
Tenant ID: $($Context.TenantId)
App Permissions: $($permissionsObject.Graph)
Authorized Client IP: $((Invoke-WebRequest ifconfig.me/ip).Content.Trim())
Client Hostname: $env:COMPUTERNAME
"@
                # 6) Register the new enterprise app for Graph
                $appRegistration = New-TkAppRegistration `
                    -DisplayName $AppSettings.AppName `
                    -CertThumbprint $CertDetails.CertThumbprint `
                    -RequiredResourceAccessList $AppSettings.RequiredResourceAccessList `
                    -SignInAudience 'AzureADMyOrg' `
                    -Notes $Notes `
                    -ErrorAction Stop
                # 7) Configure the service principal, permissions, etc.
                $ConsentUrl = Initialize-TkAppSpRegistration `
                    -AppRegistration $appRegistration `
                    -Context $Context `
                    -RequiredResourceAccessList $AppSettings.RequiredResourceAccessList `
                    -Scopes $permissionsObject `
                    -AuthMethod 'Certificate' `
                    -CertThumbprint $CertDetails.CertThumbprint `
                    -ErrorAction Stop
                [void](Read-Host 'Provide admin consent now, or copy the url and provide admin consent later. Press Enter to continue.')
                # 8) Create the Exchange Online policy restricting send
                [void](New-TkExchangeEmailAppPolicy -AppRegistration $appRegistration -MailEnabledSendingGroup $MailEnabledSendingGroup)
                # 9) Build final output object
                $output = [PSCustomObject]@{
                    AppId                  = $appRegistration.AppId
                    Id                     = $appRegistration.Id
                    AppName                = "CN=$($AppSettings.AppName)"
                    AppRestrictedSendGroup = $MailEnabledSendingGroup
                    CertExpires            = $CertDetails.CertExpires
                    CertThumbprint         = $CertDetails.CertThumbprint
                    ConsentUrl             = $ConsentUrl
                    DefaultDomain          = $MailEnabledSendingGroup.Split('@')[1]
                    SendAsUser             = ($AppSettings.User.UserPrincipalName.Split('@')[0])
                    SendAsUserEmail        = $AppSettings.User.UserPrincipalName
                    TenantID               = $Context.TenantId
                }
                $graphEmailApp = [TkEmailAppParams]::new(
                    $output.AppId,
                    $output.Id,
                    $output.AppName,
                    $output.AppRestrictedSendGroup,
                    $output.CertExpires,
                    $output.CertThumbprint,
                    $output.ConsentUrl,
                    $output.DefaultDomain,
                    $output.SendAsUser,
                    $output.SendAsUserEmail,
                    $output.TenantID
                )
                # 10) Store it as JSON in the vault
                $secretName = "CN=$($AppSettings.AppName)"
                $savedSecretName = Set-TkJsonSecret -Name $secretName -InputObject $output -VaultName $VaultName -Overwrite:$OverwriteVaultSecret
                Write-AuditLog "Secret '$savedSecretName' saved to vault '$VaultName'."
            }
            catch {
                throw
            }
        }
        else {
            Write-AuditLog 'User elected not to create or configure the Graph Email App. (ShouldProcess => false).'
        }
    }
    end {
        if ($ReturnParamSplat) {
            return ($graphEmailApp | ConvertTo-ParameterSplat)
        }
        else {
            return $graphEmailApp
        }
        Write-AuditLog -EndFunction
    }
}
