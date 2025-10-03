<#
    .SYNOPSIS
        Publishes a new or existing Graph Email App with specified configurations.
    .DESCRIPTION
        The Publish-TkEmailApp function creates or configures a Graph Email App in Azure AD. It supports two scenarios:
        1. Creating a new app with specified parameters.
        2. Using an existing app and attaching a certificate to it.
    .PARAMETER AppPrefix
        The prefix used to initialize the Graph Email App. Must be 2-4 characters, letters, and numbers only. The default value is 'Gtk'.
    .PARAMETER AuthorizedSenderUserName
        The username of the authorized sender. Must be a valid email address.
    .PARAMETER MailEnabledSendingGroup
        The mail-enabled security group. Must be a valid email address.
    .PARAMETER ExistingAppObjectId
        The AppId of the existing App Registration to which you want to attach a certificate. Must be a valid GUID.
    .PARAMETER CertPrefix
        Prefix to add to the certificate subject for the existing app.
    .PARAMETER CertThumbprint
        The thumbprint of the certificate to be retrieved. Must be a valid 40-character hexadecimal string.
    .PARAMETER KeyExportPolicy
        Key export policy for the certificate. Valid values are 'Exportable' and 'NonExportable'. The default value is 'NonExportable'.
    .PARAMETER VaultName
        If specified, use a custom vault name. Otherwise, use the default 'GraphEmailAppLocalStore'.
    .PARAMETER OverwriteVaultSecret
        If specified, overwrite the vault secret if it already exists.
    .PARAMETER ReturnParamSplat
        If specified, return the parameter splat for use in other functions.
    .PARAMETER DoNotUseDomainSuffix
        Switch to add session domain suffix to the app name.
    .PARAMETER LogOutput
        If specified, log the output to the console.
    .EXAMPLE
        # Permissions required for app registration:
            - 'Application.ReadWrite.All'
            - 'DelegatedPermissionGrant.ReadWrite.All'
            - 'Directory.ReadWrite.All'
            - 'RoleManagement.ReadWrite.Directory'
        # Permissions granted to the app:
            - 'Mail.Send' (Application) - Send mail as any user
            # Exchange application policy restricts send to a mail enabled security group
        # Ensure a mail enabled sending group is created first:
            $DefaultDomain = 'contoso.com'
            $MailEnabledSendingGroupToCreate = "CTSO-GraphAPIMail"
        # Creates a mail-enabled security group named "MySenders" using a default domain
            $group = New-MailEnabledSendingGroup -Name $MailEnabledSendingGroupToCreate -DefaultDomain $DefaultDomain
        # Create a new Graph Email App for a single tenant
            $LicensedUserToSendAs = 'helpdesk@contoso.com'
            Publish-TkEmailApp `
                -AuthorizedSenderUserName $LicensedUserToSendAs `
                -MailEnabledSendingGroup $group.PrimarySmtpAddress `
                -ReturnParamSplat
        # Returns an app named like 'GraphToolKit-Gtk-<Session AD Domain>-As-helpdesk'
        # Returns a param splat that can be used as input for the send mail function:
        # Example:
            $params = @{
                AppId                  = 'your-app-id'
                Id                     = 'your-app-object-id'
                AppName                = 'GraphToolKit-Gtk-<Session AD Domain>-As-helpdesk'
                CertificateSubject     = 'GraphToolKit-GTK-<Session AD Domain>-As-helpdesk'
                AppRestrictedSendGroup = 'CTSO-GraphAPIMail@contoso.com'
                CertExpires            = 'yyyy-MM-dd HH:mm:ss'
                CertThumbprint         = 'your-cert-thumbprint'
                ConsentUrl             = 'https://login.microsoftonline.com/<your-tenant-id>/adminconsent?client_id=<your-app-id>'
                DefaultDomain          = 'contoso.com'
                SendAsUser             = 'helpdesk'
                SendAsUserEmail        = 'helpdesk@contoso.com'
                TenantID               = 'your-tenant-id'
            }
    .EXAMPLE
        # Create a multi client app registration where one app exists and multiple certificates are associated to the app:
        # Initial setup:
        # Create the group as before (or reuse the existing group) and run the following commands:
            $LicensedUserToSendAs = 'helpdesk@contoso.com'
            $CertPrefix = "CTSO" # First Company prefix. This will be used to prefix the certificate subject.
            Publish-TkEmailApp `
                -CertPrefix $CertPrefix `
                -AuthorizedSenderUserName $LicensedUserToSendAs `
                -MailEnabledSendingGroup $group.PrimarySmtpAddress `
                -ReturnParamSplat
        # Returns an app named like 'GraphToolKit-Gtk-<Session AD Domain>-As-helpdesk'
            $params = @{
                AppId                  = 'your-app-id'
                Id                     = 'your-app-object-id'
                AppName                = 'GraphToolKit-Gtk-<Session AD Domain>-As-helpdesk'
                CertificateSubject     = 'GraphToolKit-CTSO-<Session AD Domain>-As-helpdesk'
                AppRestrictedSendGroup = 'CTSO-GraphAPIMail@contoso.com'
                CertExpires            = 'yyyy-MM-dd HH:mm:ss'
                CertThumbprint         = 'your-cert-thumbprint'
                ConsentUrl             = 'https://login.microsoftonline.com/<your-tenant-id>/adminconsent?client_id=<your-app-id>'
                DefaultDomain          = 'contoso.com'
                SendAsUser             = 'helpdesk'
                SendAsUserEmail        = 'helpdesk@contoso.com'
                TenantID               = 'your-tenant-id'
            }
            $useExistingParams = @{
                ExistingAppObjectId  = $params.Id
                CertPrefix           = 'NewCompany'
                OverwriteVaultSecret = $true      # optional, if you want to overwrite the existing vault secret
                ReturnParamSplat     = $true      # optional, returns the param splat
            }
            Publish-TkEmailApp @useExistingParams
        # The new Cert will be prefixed with the new company prefix and will allow the current client to authenticate.
        # Back in the app registrations console, if you look at the internal notes in the properties of the app:
        # The app's "Internal Notes" will be populated with the following json:
        # Assists in tracking the app's usage and configuration.
            {
                "GraphEmailAppFor": "helpdesk@contoso.com",
                "RestrictedToGroup": "CTSO-GraphAPIMail@contoso.com",
                "AppPermissions": "Mail.Send",
                "New-Company_ClientIP": "<Public IP Address of the client where the app was called>",
                "New-Company_Host": "<Host of the client where the app was called>",
                "NewCoolCompany_ClientIP": "<Public IP Address of the client where the app was called>",
                "NewCoolCompany_Host": "Host of the client where the app was called>"
            }
            # New cert additions added through the toolkit will append new client info to these notes.
    .NOTES
        This cmdlet requires that the user running the cmdlet have the necessary permissions to create the app and connect to Exchange Online.
#>
function Publish-TkEmailApp {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'Interactive')]
    param (
        # REGION: INTERACTIVE (default) — no parameters needed

        # REGION: CREATE NEW APP
        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNewApp')]
        [ValidatePattern('^[A-Z0-9]{2,4}$')]
        [string]
        $AppPrefix = 'Gtk',

        [Parameter(Mandatory = $true, ParameterSetName = 'CreateNewApp')]
        [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')]
        [string]
        $AuthorizedSenderUserName,

        [Parameter(Mandatory = $true, ParameterSetName = 'CreateNewApp')]
        [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')]
        [string]
        $MailEnabledSendingGroup,

        # REGION: USE EXISTING APP
        [Parameter(Mandatory = $true, ParameterSetName = 'UseExistingApp')]
        [ValidatePattern('^[0-9a-fA-F-]{36}$')]
        [string]
        $ExistingAppObjectId,

        [Parameter(Mandatory = $true, ParameterSetName = 'UseExistingApp')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNewApp')]
        [string]
        $CertPrefix,

        # REGION: Shared parameters (must declare all sets explicitly)
        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNewApp')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseExistingApp')]
        [ValidatePattern('^[A-Fa-f0-9]{40}$')]
        [string]
        $CertThumbprint,

        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNewApp')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseExistingApp')]
        [ValidateSet('Exportable', 'NonExportable')]
        [string]
        $KeyExportPolicy = 'NonExportable',

        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNewApp')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseExistingApp')]
        [string]
        $VaultName = 'GraphEmailAppLocalStore',

        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNewApp')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseExistingApp')]
        [switch]
        $OverwriteVaultSecret,

        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNewApp')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseExistingApp')]
        [switch]
        $ReturnParamSplat,

        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNewApp')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseExistingApp')]
        [switch]
        $DoNotUseDomainSuffix,

        [Parameter(Mandatory = $false, ParameterSetName = 'CreateNewApp')]
        [Parameter(Mandatory = $false, ParameterSetName = 'UseExistingApp')]
        [string]
        $LogOutput
    )
    begin {
        if ($PSCmdlet.ParameterSetName -eq 'Interactive') {
            Write-Verbose "Welcome to the GraphAppToolkit Email App Publisher!" -Verbose
            Write-Verbose "Please select an option:" -Verbose
            Write-Verbose "   1) Create a new app registration." -Verbose
            Write-Verbose "   2) Use an existing app registration." -Verbose
            $choice = Read-Host "Enter 1 or 2"
            switch ($choice) {
                '1' {
                    $AuthorizedSenderUserName = Read-Host "Enter the authorized sender's email (e.g., user@example.com)"
                    $hasGroup = Read-Host "Have you already created a mail-enabled security group? (y/n)"
                    if ($hasGroup -ne 'y') {
                        $createGroup = Read-Host "Would you like to create one now? (y/n)"
                        if ($createGroup -eq 'y') {
                            $groupName = Read-Host "Enter a name for the Mail Enabled Sending Group (e.g., CTSO-GraphAPIMail)"
                            $defaultDomain = Read-Host "Enter your default email domain (e.g., contoso.com) that will be appended to the group name. (e.g., CTSO-GraphAPIMail@contoso.com)"
                            Write-Verbose "Creating Mail Enabled Sending Group '$groupName' in domain '$defaultDomain'..." -Verbose
                            $group = New-MailEnabledSendingGroup -Name $groupName -DefaultDomain $defaultDomain -Verbose -InformationAction Continue
                            $MailEnabledSendingGroup = $group.PrimarySmtpAddress
                            if (-not $MailEnabledSendingGroup) {
                                throw "Could not determine the group's PrimarySmtpAddress. Ensure the group was created successfully."
                            }
                        }
                        else {
                            Write-Verbose "You must provide a mail-enabled security group to proceed. Please run the command again after creating one." -Verbose
                            return
                        }
                    }
                    else {
                        $MailEnabledSendingGroup = Read-Host "Enter the mail-enabled sending group (e.g., group@example.com)"
                    }
                    $AppPrefixInput = Read-Host "Enter the app prefix (default is 'Gtk')"
                    if ([string]::IsNullOrEmpty($AppPrefixInput)) { $AppPrefixInput = 'Gtk' }
                    return Publish-TkEmailApp -AuthorizedSenderUserName $AuthorizedSenderUserName `
                        -MailEnabledSendingGroup $MailEnabledSendingGroup -AppPrefix $AppPrefixInput
                }
                '2' {
                    $ExistingAppObjectId = Read-Host "Enter the existing App's ObjectId (GUID)"
                    $CertPrefixInput = Read-Host "Enter the certificate prefix"
                    return Publish-TkEmailApp -ExistingAppObjectId $ExistingAppObjectId -CertPrefix $CertPrefixInput
                }
                default {
                    Write-Verbose "Invalid selection. Please run the command again." -Verbose
                    return
                }
            }
        }
        if (-not $script:LogString) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }
        try {
            Write-AuditLog '###############################################'
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
            $scopesNeeded = @(
                'Application.ReadWrite.All',
                'DelegatedPermissionGrant.ReadWrite.All',
                'Directory.ReadWrite.All'
            )
        }
        catch {
            throw
        }
    }
    process {
        $target = if ($AppPrefix) { $AppPrefix } else { $CertPrefix }
        $shouldProcessTarget = "Graph Email App $target"
        $shouldProcessOperation = 'Publish-TkEmailApp'
        if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
            switch ($PSCmdlet.ParameterSetName) {
                # ------------------------------------------------------
                # ============== SCENARIO 1: CREATE NEW APP =============
                # ------------------------------------------------------
                'CreateNewApp' {
                    # 2) Connect to both Graph and Exchange
                    Connect-TkMsService `
                        -MgGraph `
                        -ExchangeOnline `
                        -GraphAuthScopes $scopesNeeded
                    # 3) Grab MgContext for tenant info
                    $Context = Get-MgContext
                    if (!$Context) {
                        throw 'Could not retrieve the context for the tenant.'
                    }
                    # 1) Validate the user (AuthorizedSenderUserName) is in tenant
                    $user = Get-MgUser -Filter "Mail eq '$AuthorizedSenderUserName'"
                    if (-not $user) {
                        throw "User '$AuthorizedSenderUserName' not found in the tenant."
                    }
                    # 2) Build the app context (Mail.Send permission, etc.)
                    $AppSettings = Initialize-TkRequiredResourcePermissionObject `
                        -GraphPermissions 'Mail.Send'
                    $appName = Initialize-TkAppName `
                        -Prefix $AppPrefix `
                        -UserId $AuthorizedSenderUserName `
                        -DoNotUseDomainSuffix:$DoNotUseDomainSuffix `
                        -ErrorAction Stop
                    # Verify if the secret already exists in the vault
                    $existingSecret = Get-TkExistingSecret `
                        -AppName $appName `
                        -VaultName $VaultName `
                        -ErrorAction SilentlyContinue
                    if ($ExistingSecret -and -not $OverwriteVaultSecret) {
                        throw "Secret '$AppName' already exists in vault '$VaultName'. Use the -OverwriteVaultSecret switch to overwrite it."
                    }
                    # Add relevant properties
                    $AppSettings | Add-Member -NotePropertyName 'User' -NotePropertyValue $user
                    $AppSettings | Add-Member -NotePropertyName 'AppName' -NotePropertyValue $appName
                    if ($CertPrefix) {
                        $updatedString = $appName -replace '(GraphToolKit-)[A-Za-z0-9]{2,4}(?=-)', "`$1$CertPrefix"
                        $CertificateSubject = "CN=$updatedString"
                        $ClientCertPrefix = "$certPrefix"
                    }
                    else {
                        $CertificateSubject = "CN=$appName"
                        $ClientCertPrefix = "$AppPrefix"
                    }
                    # 3) Create or retrieve the certificate
                    $AppAuthCertificateParams = @{
                        AppName         = $AppSettings.AppName
                        Thumbprint      = $CertThumbprint
                        Subject         = $CertificateSubject
                        KeyExportPolicy = $KeyExportPolicy
                        ErrorAction     = 'Stop'
                    }
                    $CertDetails = Initialize-TkAppAuthCertificate @AppAuthCertificateParams
                    # 4) Show the proposed object
                    $proposedObject = [PSCustomObject]@{
                        ProposedAppName                 = $AppSettings.AppName
                        ProposedCertificateSubject      = $CertificateSubject
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
                    Write-AuditLog ($proposedObject | Format-List | Out-String)
                    # 5) Only proceed if ShouldProcess is allowed
                    try {
                        # Build a hashtable (or PSCustomObject) of the fields you want:
                        $notesHash = [ordered]@{
                            GraphEmailAppFor                  = $AuthorizedSenderUserName
                            RestrictedToGroup                 = $MailEnabledSendingGroup
                            AppPermissions                    = 'Mail.Send'
                            ($ClientCertPrefix + '_ClientIP') = (Invoke-RestMethod ifconfig.me/ip)
                            ($ClientCertPrefix + '_Host')     = $env:COMPUTERNAME
                        }
                        # Convert that hashtable to a JSON string:
                        $Notes = $notesHash | ConvertTo-Json #-Compress
                        # 6) Register the new enterprise app for Graph
                        $AppRegistrationParams = @{
                            DisplayName                = $AppSettings.AppName
                            CertThumbprint             = $CertDetails.CertThumbprint
                            RequiredResourceAccessList = $AppSettings.RequiredResourceAccessList
                            SignInAudience             = 'AzureADMyOrg'
                            Notes                      = $Notes
                            ErrorAction                = 'Stop'
                        }
                        $appRegistration = New-TkAppRegistration @AppRegistrationParams
                        # 7) Initialize the service principal, permissions, etc.
                        $AppSpRegistrationParams = @{
                            AppRegistration            = $appRegistration
                            Context                    = $Context
                            RequiredResourceAccessList = $AppSettings.RequiredResourceAccessList
                            Scopes                     = $permissionsObject
                            AuthMethod                 = 'Certificate'
                            CertThumbprint             = $CertDetails.CertThumbprint
                            ErrorAction                = 'Stop'
                        }
                        $ConsentUrl = New-TkAppSpOauth2Registration @AppSpRegistrationParams
                        [void](Read-Host 'Provide admin consent now, or copy the url and provide admin consent later. Press Enter to continue.')
                        # 8) Create the Exchange Online policy restricting send
                        New-TkExchangeEmailAppPolicy `
                            -AppRegistration $appRegistration `
                            -MailEnabledSendingGroup $MailEnabledSendingGroup `
                            -AuthorizedSenderUserName $AuthorizedSenderUserName
                        # 9) Build final output object
                        $EmailAppParams = @{
                            AppId                  = $appRegistration.AppId
                            Id                     = $appRegistration.Id
                            AppName                = "$($AppSettings.AppName)"
                            CertificateSubject     = $CertificateSubject
                            AppRestrictedSendGroup = $MailEnabledSendingGroup
                            CertExpires            = $CertDetails.CertExpires
                            CertThumbprint         = $CertDetails.CertThumbprint
                            ConsentUrl             = $ConsentUrl
                            DefaultDomain          = $MailEnabledSendingGroup.Split('@')[1]
                            SendAsUser             = $AppSettings.User.UserPrincipalName.Split('@')[0]
                            SendAsUserEmail        = $AppSettings.User.UserPrincipalName
                            TenantID               = $Context.TenantId
                        }
                        [TkEmailAppParams]$graphEmailApp = Initialize-TkEmailAppParamsObject @EmailAppParams
                        # 10) Store it as JSON in the vault
                        $JsonSecretParams = @{
                            Name        = "CN=$($AppSettings.AppName)"
                            InputObject = $graphEmailApp
                            VaultName   = $VaultName
                            Overwrite   = $OverwriteVaultSecret
                            ErrorAction = 'Stop'
                        }
                        $savedSecretName = Set-TkJsonSecret @JsonSecretParams
                        Write-AuditLog "Secret '$savedSecretName' saved to vault '$VaultName'."
                    }
                    catch {
                        throw
                    }
                }
                # ---------------------------------------------------------
                # ============ SCENARIO 2: USE EXISTING APP ===============
                # ---------------------------------------------------------
                'UseExistingApp' {
                    # Grab MgContext for tenant info
                    Connect-TkMsService `
                        -MgGraph `
                        -GraphAuthScopes $scopesNeeded
                    $Context = Get-MgContext
                    if (!$Context) {
                        throw 'Could not retrieve the context for the tenant.'
                    }
                    $ClientCertPrefix = "$CertPrefix"
                    # Retrieve the existing app registration by AppId
                    Write-AuditLog "Looking up existing app with ObjectId: $ExistingAppObjectId"
                    # Get-MgApplication uses the application object id, not the app id
                    $existingApp = Get-MgApplication -ApplicationId $ExistingAppObjectId -ErrorAction Stop
                    if (-not $existingApp) {
                        throw "Could not find an existing application with AppId '$ExistingAppObjectId'."
                    }
                    if (!($existingApp | Where-Object { $_.DisplayName -like 'GraphToolKit-*' })) {
                        throw "The existing app with AppId '$ExistingAppObjectId' is not a GraphToolKit app."
                    }
                    $updatedString = $existingApp.DisplayName -replace '(GraphToolKit-)[A-Za-z0-9]{2,4}(?=-)', "`$1$CertPrefix"
                    # Retrieve or create the certificate
                    $certParams = @{
                        AppName         = $updatedString
                        Thumbprint      = $CertThumbprint
                        Subject         = "CN=$updatedString"
                        KeyExportPolicy = $KeyExportPolicy
                        ErrorAction     = 'Stop'
                    }
                    $certDetails = Initialize-TkAppAuthCertificate @certParams
                    Write-AuditLog "Attaching certificate (Thumbprint: $($certDetails.CertThumbprint)) to existing app '$($existingApp.DisplayName)'."
                    # Merge or append the new certificate to the existing KeyCredentials
                    $currentKeys = $existingApp.KeyCredentials
                    $newCert = @{
                        Type        = 'AsymmetricX509Cert'
                        Usage       = 'Verify'
                        Key         = (Get-ChildItem -Path Cert:\CurrentUser\My |
                            Where-Object { $_.Thumbprint -eq $certDetails.CertThumbprint }).RawData
                        DisplayName = "CN=$updatedString"
                    }
                    # If you want to specify start/end date, you can do so as well:
                    # $newCert.StartDateTime = (Get-Date)
                    # $newCert.EndDateTime   = (Get-Date).AddYears(1)
                    # Append the new cert to existing
                    $mergedKeys = $currentKeys + $newCert
                    $existingNotesRaw = $existingApp.Notes
                    if (-not [string]::IsNullOrEmpty($existingNotesRaw)) {
                        try {
                            $notesObject = $existingNotesRaw | ConvertFrom-Json -ErrorAction Stop
                        }
                        catch {
                            Write-AuditLog 'Existing .Notes was not valid JSON; ignoring it.'
                            $notesObject = [ordered]@{}
                        }
                    }
                    else {
                        $notesObject = [ordered]@{}
                    }
                    # Add your new properties each time the function runs
                    $notesObject | Add-Member -NotePropertyName ($clientCertPrefix + '_ClientIP') -NotePropertyValue (Invoke-RestMethod ifconfig.me/ip)
                    $notesObject | Add-Member -NotePropertyName ($clientCertPrefix + '_Host') -NotePropertyValue $env:COMPUTERNAME
                    $updatedNotes = $notesObject | ConvertTo-Json #-Compress
                    if (($updatedNotes.length -gt 1024)) {
                        throw 'The Notes object is too large. Please reduce the size of the Notes object.'
                    }
                    try {
                        # Update the application with the new KeyCredentials array
                        $updateAppParams = @{
                            ApplicationId  = $existingApp.Id
                            KeyCredentials = $mergedKeys
                            Notes          = $updatedNotes
                            ErrorAction    = 'Stop'
                        }
                        Update-MgApplication @updateAppParams | Out-Null
                        # Build an output object similar to "new" scenario
                        $emailAppParams = @{
                            AppId                  = $existingApp.AppId
                            Id                     = $existingApp.Id
                            AppName                = "$updatedString"
                            CertificateSubject     = "CN=$updatedString"
                            AppRestrictedSendGroup = $notesObject.RestrictedToGroup
                            CertExpires            = $certDetails.CertExpires
                            CertThumbprint         = $certDetails.CertThumbprint
                            ConsentUrl             = $null
                            DefaultDomain          = ($notesObject.GraphEmailAppFor.Split('@')[1])
                            SendAsUser             = ($notesObject.GraphEmailAppFor.Split('@')[0])
                            SendAsUserEmail        = $notesObject.GraphEmailAppFor
                            TenantID               = $context.TenantId
                        }
                        [TkEmailAppParams]$graphEmailApp = Initialize-TkEmailAppParamsObject @emailAppParams
                        # Store updated info in the vault
                        $jsonSecretParams = @{
                            Name        = "CN=$updatedString"
                            InputObject = $graphEmailApp
                            VaultName   = $VaultName
                            Overwrite   = $OverwriteVaultSecret
                            ErrorAction = 'Stop'
                        }
                        $savedSecretName = Set-TkJsonSecret @JsonSecretParams
                        Write-AuditLog "Secret for existing app saved as '$savedSecretName' in vault '$VaultName'."
                    }
                    catch {
                        throw
                    }
                }
            } # end switch
        }
    }
    end {
        if ($ReturnParamSplat -and $graphEmailApp) {
            return ($graphEmailApp | ConvertTo-ParameterSplat)
        }
        elseif ($graphEmailApp) {
            return $graphEmailApp
        }
        if ($LogOutput) {
            Write-AuditLog -End -LogOutput $LogOutput
        }
    }
}

