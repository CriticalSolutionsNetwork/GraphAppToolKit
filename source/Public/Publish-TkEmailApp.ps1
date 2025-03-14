<#
    .SYNOPSIS
        Publishes a new or existing Graph Email App with specified configurations.
    .DESCRIPTION
        The Publish-TkEmailApp function creates or configures a Graph Email App in Azure AD. It supports two scenarios:
        1. Creating a new app with specified parameters.
        2. Using an existing app and attaching a certificate to it.
    .PARAMETER AppPrefix
        The prefix used to initialize the Graph Email App. Must be 2-4 characters, letters, and numbers only. Default is 'Gtk'.
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
        Key export policy for the certificate. Valid values are 'Exportable' and 'NonExportable'. Default is 'NonExportable'.
    .PARAMETER VaultName
        If specified, use a custom vault name. Otherwise, use the default 'GraphEmailAppLocalStore'.
    .PARAMETER OverwriteVaultSecret
        If specified, overwrite the vault secret if it already exists.
    .PARAMETER ReturnParamSplat
        If specified, return the parameter splat for use in other functions.
    .EXAMPLE
        Publish-TkEmailApp -AppPrefix 'Gtk' -AuthorizedSenderUserName 'user@example.com' -MailEnabledSendingGroup 'group@example.com'

        Creates a new Graph Email App with the specified parameters.
    .EXAMPLE
        Publish-TkEmailApp -ExistingAppObjectId '12345678-1234-1234-1234-1234567890ab' -CertPrefix 'Cert'

    Uses an existing app and attaches a certificate with the specified prefix.
    .NOTES
        This cmdlet requires that the user running the cmdlet have the necessary permissions to create the app and connect to Exchange Online.
        Permissions required:
        - 'Application.ReadWrite.All'
        - 'DelegatedPermissionGrant.ReadWrite.All'
        - 'Directory.ReadWrite.All'
        - 'RoleManagement.ReadWrite.Directory'

#>
function Publish-TkEmailApp {
    [CmdletBinding(ConfirmImpact = 'High', DefaultParameterSetName = 'CreateNewApp')]
    param(
        # REGION: CREATE NEW APP param set
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'CreateNewApp',
            HelpMessage = `
                'The prefix used to initialize the Graph Email App. 2-4 characters letters and numbers only.'
        )]
        [ValidatePattern('^[A-Z0-9]{2,4}$')]
        [string]
        $AppPrefix = 'Gtk',
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'CreateNewApp',
            HelpMessage = `
                'The username of the authorized sender.'
        )]
        [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')]
        [string]
        $AuthorizedSenderUserName,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'CreateNewApp',
            HelpMessage = `
                'The Mail Enabled Sending Group.'
        )]
        [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')]
        [string]
        $MailEnabledSendingGroup,
        # REGION: USE EXISTING APP param set
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'UseExistingApp',
            HelpMessage = `
                'The AppId of the existing App Registration to which you want to attach a certificate.'
        )]
        [ValidatePattern('^[0-9a-fA-F-]{36}$')]
        [string]
        $ExistingAppObjectId,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'UseExistingApp',
            HelpMessage = `
                'Prefix to add to certificate subject for existing app.'
        )]
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'CreateNewApp',
            HelpMessage = `
                'Prefix to add to certificate subject for existing app.'
        )]
        [string]
        $CertPrefix,
        # REGION: Shared parameters
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'The thumbprint of the certificate to be retrieved.'
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
        $VaultName = 'GraphEmailAppLocalStore',
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
                'Return the parameter splat for use in other functions.'
        )]
        [switch]
        $ReturnParamSplat
    )
    begin {
        <#
            This cmdlet requires that the user running the cmdlet have the necessary permissions to
            create the app and connect to Exchange Online. In addition, a mail-enabled security group
            must already exist in Exchange Online for the MailEnabledSendingGroup parameter.
            Permissions required:
                'Application.ReadWrite.All',
                'DelegatedPermissionGrant.ReadWrite.All',
                'Directory.ReadWrite.All',
                'RoleManagement.ReadWrite.Directory'
        #>
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
                    -ScenarioName 'AuditGraphEmail' `
                    -UserId $AuthorizedSenderUserName
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
                    $CertName = "CN=$updatedString"
                    $ClientCertPrefix = "$certPrefix"
                }
                else {
                    $CertName = "CN=$appName"
                    $ClientCertPrefix = "$AppPrefix"
                }
                # 3) Create or retrieve the certificate
                $AppAuthCertificateParams = @{
                    AppName         = $AppSettings.AppName
                    Thumbprint      = $CertThumbprint
                    Subject         = $CertName
                    KeyExportPolicy = $KeyExportPolicy
                    ErrorAction     = 'Stop'
                }
                $CertDetails = Initialize-TkAppAuthCertificate @AppAuthCertificateParams
                # 4) Show the proposed object
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
                    $ConsentUrl = Initialize-TkAppSpRegistration @AppSpRegistrationParams
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
                        AppName                = "CN=$($AppSettings.AppName)"
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
                $notesObject | Add-Member -NotePropertyName ($ClientCertPrefix + '_ClientIP') -NotePropertyValue (Invoke-RestMethod ifconfig.me/ip)
                $notesObject | Add-Member -NotePropertyName ($ClientCertPrefix + '_Host') -NotePropertyValue $env:COMPUTERNAME
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
                    $EmailAppParams = @{
                        AppId                  = $existingApp.AppId
                        Id                     = $existingApp.Id
                        AppName                = "CN=$updatedString"
                        AppRestrictedSendGroup = $notesObject.RestrictedToGroup
                        CertExpires            = $CertDetails.CertExpires
                        CertThumbprint         = $CertDetails.CertThumbprint
                        ConsentUrl             = $null
                        DefaultDomain          = ($notesObject.GraphEmailAppFor.Split('@')[1])
                        SendAsUser             = ($notesObject.GraphEmailAppFor.Split('@')[0])
                        SendAsUserEmail        = $notesObject.GraphEmailAppFor
                        TenantID               = $Context.TenantID
                    }
                    [TkEmailAppParams]$graphEmailApp = Initialize-TkEmailAppParamsObject @EmailAppParams
                    # Store updated info in the vault
                    $JsonSecretParams = @{
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
    end {
        if ($ReturnParamSplat -and $graphEmailApp) {
            return ($graphEmailApp | ConvertTo-ParameterSplat)
        }
        elseif ($graphEmailApp) {
            return $graphEmailApp
        }
        Write-AuditLog -EndFunction
    }
}

