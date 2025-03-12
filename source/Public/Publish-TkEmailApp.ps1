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
    .PARAMETER AuthorizedSenderUserName
        The username of the authorized sender.
    .PARAMETER MailEnabledSendingGroup
        The mail-enabled group to which the sender belongs. This will be used to assign
        app policy restrictions.
    .PARAMETER CertThumbprint
        An optional parameter indicating the thumbprint of the certificate to be retrieved. If not
        specified, a self-signed certificate will be generated.
    .PARAMETER KeyExportPolicy
        Specifies the key export policy for the newly created certificate. Valid values are
        'Exportable' or 'NonExportable'. Defaults to 'NonExportable'.
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
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'CreateNewApp')]
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
                $Context = Get-MgContext -ErrorAction Stop
                # 1) Validate the user (AuthorizedSenderUserName) is in tenant
                $user = Get-MgUser -Filter "Mail eq '$AuthorizedSenderUserName'"
                if (-not $user) {
                    throw "User '$AuthorizedSenderUserName' not found in the tenant."
                }
                # 2) Build the app context (Mail.Send permission, etc.)
                $AppSettings = New-TkRequiredResourcePermissionObject `
                    -GraphPermissions 'Mail.Send'
                $appName = New-TkAppName `
                    -Prefix $AppPrefix `
                    -ScenarioName 'AuditGraphEmail' `
                    -UserId $AuthorizedSenderUserName
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
                if ($PSCmdlet.ShouldProcess("GraphEmailApp '$($AppSettings.AppName)'",
                        'Creating & configuring a new Graph Email App in Azure AD')) {
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
                            -MailEnabledSendingGroup $MailEnabledSendingGroup | Out-Null
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
                        [TkEmailAppParams]$graphEmailApp = New-TkEmailAppParams @EmailAppParams
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
                else {
                    Write-AuditLog 'User elected not to create or configure the Graph Email App. (ShouldProcess => false).'
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
                $Context = Get-MgContext -ErrorAction Stop
                $ClientCertPrefix = "$CertPrefix"
                # Retrieve the existing app registration by AppId
                Write-AuditLog "Looking up existing app with ObjectId: $ExistingAppObjectId"
                # Get-MgApplication uses the application object id, not the app id
                $existingApp = Get-MgApplication -ApplicationId $ExistingAppObjectId -ErrorAction Stop
                if (!($existingApp | Where-Object { $_.DisplayName -like 'GraphToolKit-*' })) {
                    throw "The existing app with AppId '$ExistingAppObjectId' is not a GraphToolKit app."
                }
                if (-not $existingApp) {
                    throw "Could not find an existing application with AppId '$ExistingAppObjectId'."
                }
                $updatedString = $existingApp.DisplayName -replace '(GraphToolKit-)[A-Za-z0-9]{2,4}(?=-)', "`$1$CertPrefix"
                # Retrieve or create the certificate
                $certDetails = Initialize-TkAppAuthCertificate `
                    -AppName $updatedString `
                    -Thumbprint $CertThumbprint `
                    -Subject ("CN=$updatedString") `
                    -KeyExportPolicy $KeyExportPolicy `
                    -ErrorAction Stop
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
                if ($PSCmdlet.ShouldProcess("AppId '$ExistingAppObjectId'",
                        "Adding a new certificate to existing App '$($existingApp.DisplayName)'")) {
                    try {
                        # Update the application with the new KeyCredentials array
                        Update-MgApplication `
                            -ApplicationId $existingApp.Id `
                            -KeyCredentials $mergedKeys `
                            -Notes $updatedNotes `
                            -ErrorAction Stop | Out-Null
                        # Build an output object similar to "new" scenario
                        $EmailAppParams = @{
                            AppId                  = $appRegistration.AppId
                            Id                     = $appRegistration.Id
                            AppName                = "CN=$updatedString"
                            AppRestrictedSendGroup = $MailEnabledSendingGroup
                            CertExpires            = $CertDetails.CertExpires
                            CertThumbprint         = $CertDetails.CertThumbprint
                            ConsentUrl             = $null
                            DefaultDomain          = ($notesObject.GraphEmailAppFor.Split('@')[1])
                            SendAsUser             = ($notesObject.GraphEmailAppFor.Split('@')[0])
                            SendAsUserEmail        = $notesObject.GraphEmailAppFor
                            TenantID               = $output.TenantID
                        }
                        [TkEmailAppParams]$graphEmailApp = New-TkEmailAppParams @EmailAppParams
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
                else {
                    Write-AuditLog "User canceled updating existing app '$($existingApp.DisplayName)'."
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

