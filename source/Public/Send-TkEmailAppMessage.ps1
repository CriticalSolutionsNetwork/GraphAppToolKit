<#
    .SYNOPSIS
        Sends an email using the Microsoft Graph API, either by retrieving app credentials from a local vault
        or by specifying them manually.
    .DESCRIPTION
        The Send-TkEmailAppMessage function uses the Microsoft Graph API to send an email to a specified
        recipient. It supports two parameter sets:

        1. 'Vault' (default): Provide an existing app name (AppName) whose credentials are stored in the local
            secret vault (e.g., GraphEmailAppLocalStore). The function retrieves the AppId, TenantId, and
            certificate thumbprint automatically.
        2. 'Manual': Provide the AppId, TenantId, and certificate thumbprint yourself, bypassing the vault.
        In both cases, the function obtains an OAuth2 token (via MSAL.PS) using the specified certificate
        and uses the Microsoft Graph 'sendMail' endpoint to deliver the message.
    .PARAMETER AppName
        [Vault Parameter Set Only]
        The name of the pre-created Microsoft Graph Email App (stored in GraphEmailAppLocalStore).
        This parameter is used only if the 'Vault' parameter set is chosen. The function retrieves
        the AppId, TenantId, and certificate thumbprint from the vault entry.
    .PARAMETER AppId
        [Manual Parameter Set Only]
        The Azure AD application (client) ID to use for sending the email. Must be used together with
        TenantId and CertThumbprint in the 'Manual' parameter set.
    .PARAMETER TenantId
        [Manual Parameter Set Only]
        The Azure AD tenant ID (GUID or domain name). Must be used together with AppId and CertThumbprint
        in the 'Manual' parameter set.
    .PARAMETER CertThumbprint
        [Manual Parameter Set Only]
        The certificate thumbprint (in Cert:\CurrentUser\My) used for authenticating as the Azure AD app.
        Must be used together with AppId and TenantId in the 'Manual' parameter set.
    .PARAMETER To
        The email address of the recipient.
    .PARAMETER FromAddress
        The email address of the sender who is authorized to send email as configured in the Graph Email App.
    .PARAMETER Subject
        The subject line of the email.
    .PARAMETER EmailBody
        The body text of the email.
    .PARAMETER AttachmentPath
        An array of file paths for any attachments to include in the email. Each path must exist as a leaf file.
    .EXAMPLE
        # Using the 'Vault' parameter set
        Send-TkEmailAppMessage -AppName "GraphEmailApp" -To "recipient@example.com" -FromAddress "sender@example.com" `
                            -Subject "Test Email" -EmailBody "This is a test email."

        In this example, the function retrieves the app's credentials (AppId, TenantId, CertThumbprint) from the
        local vault (GraphEmailAppLocalStore) under the secret name "GraphEmailApp."
    .EXAMPLE
        # Using the 'Manual' parameter set
        Send-TkEmailAppMessage -AppId "00000000-1111-2222-3333-444444444444" -TenantId "contoso.onmicrosoft.com" `
                            -CertThumbprint "AABBCCDDEEFF11223344556677889900" -To "recipient@example.com" `
                            -FromAddress "sender@example.com" -Subject "Manual Email" -EmailBody "Hello from Manual!"

        In this example, no vault entry is used. Instead, the function directly uses the provided AppId,
        TenantId, and CertThumbprint to obtain a token and send an email.
    .NOTES
        - This function requires the Microsoft.Graph, SecretManagement, SecretManagement.JustinGrote.CredMan,
            and MSAL.PS modules to be installed and imported (handled automatically via Initialize-TkModuleEnv).
        - For the 'Vault' parameter set, the local vault secret must store JSON properties including AppId,
            TenantID, and CertThumbprint.
        - Refer to https://learn.microsoft.com/en-us/graph/outlook-send-mail for more details on sending mail
            via Microsoft Graph.
#>

function Send-TkEmailAppMessage {
    [CmdletBinding(DefaultParameterSetName = 'Vault')]
    param(
        # Use the vault-based approach (default)
        [Parameter(
            ParameterSetName = 'Vault',
            Mandatory = $true,
            HelpMessage = 'The name of the pre-created Email App from the vault.'
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppName,
        # Use the manual approach (no vault)
        [Parameter(
            ParameterSetName = 'Manual',
            Mandatory = $true,
            HelpMessage = 'Manually specify the App (Client) ID.'
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppId,
        [Parameter(
            ParameterSetName = 'Manual',
            Mandatory = $true,
            HelpMessage = 'Manually specify the Azure AD tenant (GUID or domain).'
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $TenantId,
        [Parameter(
            ParameterSetName = 'Manual',
            Mandatory = $true,
            HelpMessage = 'Manually specify the certificate thumbprint in Cert:\CurrentUser\My.'
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertThumbprint,
        # Common parameters for both parameter sets
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Vault',
            HelpMessage = 'The email address of the recipient.'
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Manual',
            HelpMessage = 'The email address of the recipient.'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')]
        [string]
        $To,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Vault',
            HelpMessage = 'The email address of the sender.'
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Manual',
            HelpMessage = 'The email address of the sender.'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')]
        [string]
        $FromAddress,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Vault',
            HelpMessage = 'The subject line of the email.'
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Manual',
            HelpMessage = 'The subject line of the email.'
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $Subject,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Vault',
            HelpMessage = 'The body text of the email.'
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Manual',
            HelpMessage = 'The body text of the email.'
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $EmailBody,
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'Vault',
            HelpMessage = 'The path to the attachment file.'
        )]
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'Manual',
            HelpMessage = 'The path to the attachment file.'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
        [string[]]
        $AttachmentPath
    )
    begin {
        if (!($script:LogString)) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }
        Write-AuditLog '###########################################################'
        # Install and import the Microsoft.Graph module. Tested: 1.22.0
        $PublicMods = `
            'Microsoft.PowerShell.SecretManagement', 'SecretManagement.JustinGrote.CredMan', 'MSAL.PS'
        $PublicVers = `
            '1.1.2', '1.0.0', '4.37.0.0'
        $params1 = @{
            PublicModuleNames      = $PublicMods
            PublicRequiredVersions = $PublicVers
            Scope                  = 'CurrentUser'
        }
        Initialize-TkModuleEnv @params1
        # If manual parameter set:
        if ($PSCmdlet.ParameterSetName -eq 'Manual') {
            $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $CertThumbprint } -ErrorAction Stop
            $GraphEmailApp = @{
                AppId          = $AppId
                CertThumbprint = $CertThumbprint
                TenantID       = $TenantId
                CertExpires    = $cert.NotAfter
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Vault') {
            # If a GraphEmailApp object was not passed in, attempt to retrieve it from the local machine
            if ($AppName) {
                try {
                    # Step 7:
                    # Define the application Name and Encrypted File Paths.
                    $Auth = Get-Secret -Name "$AppName" -Vault GraphEmailAppLocalStore -AsPlainText -ErrorAction Stop
                    $authObj = $Auth | ConvertFrom-Json
                    $GraphEmailApp = $authObj
                    $AppId = $GraphEmailApp.AppId
                    $CertThumbprint = $GraphEmailApp.CertThumbprint
                    $Tenant = $GraphEmailApp.TenantID
                    $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $CertThumbprint } -ErrorAction Stop
                }
                catch {
                    Write-Error $_.Exception.Message
                }
            } # End Region If
        }
        if (!$GraphEmailApp) {
            throw 'GraphEmailApp object not found. Please specify the GraphEmailApp object or provide the AppName and RedirectUri parameters.'
        } # End Region If
        # Instantiate the required variables for retrieving the token.
        # Retrieve the self-signed certificate from the CurrentUser's certificate store
        if (!($cert)) {
            throw "Certificate with thumbprint $CertThumbprint not found in CurrentUser's certificate store"
        } # End Region If
        Write-AuditLog 'The Certificate:'
        Write-AuditLog $CertThumbprint
        Write-AuditLog "will expire on $($GraphEmailApp.CertExpires)"
        Write-AuditLog -Message 'Retrieved Certificate with thumbprint:'
        Write-AuditLog "$CertThumbprint"
    } # End Region Begin
    Process {
        # Authenticate with Azure AD and obtain an access token for the Microsoft Graph API using the certificate
        $MSToken = Get-MsalToken -ClientCertificate $Cert -ClientId $AppId -Authority "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token" -ErrorAction Stop
        # Set up the request headers
        $authHeader = @{Authorization = "Bearer $($MSToken.AccessToken)" }
        # Set up the request URL
        $url = "https://graph.microsoft.com/v1.0/users/$($FromAddress)/sendMail"
        # Build the message body
        # Add a "from" field to the message object in $Message
        $FromField = @{
            emailAddress = @{
                address = "$($FromAddress)"
            }
        }
        $Message = @{
            message = @{
                subject      = "$Subject"
                body         = @{
                    contentType = 'text'
                    content     = "$EmailBody"
                }
                toRecipients = @(
                    @{
                        emailAddress = @{
                            address = "$To"
                        }
                    }
                )
                from         = $FromField
            }
        }
        if ($AttachmentPath) {
            Write-AuditLog -Message 'Attachments found. Processing...'
            $Message.message.attachments = @()
            foreach ($Path in $AttachmentPath) {
                $attachmentName = (Split-Path -Path $Path -Leaf)
                $attachmentBytes = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Path))
                $attachment = @{
                    '@odata.type'  = '#microsoft.graph.fileAttachment'
                    'Name'         = $attachmentName
                    'ContentBytes' = $attachmentBytes
                }
                $Message.message.attachments += $attachment
            }
        }
        $jsonMessage = $message | ConvertTo-Json -Depth 4
        $body = $jsonMessage
        Write-AuditLog -Message 'Processed message body. Ready to send email.'
    }
    End {
        try {
            # Send the email message using the Invoke-RestMethod cmdlet
            Write-AuditLog 'Sending email via Microsoft Graph.'
            [void](Invoke-RestMethod -Headers $authHeader -Uri $url -Body $body -Method POST -ContentType 'application/json' -ErrorAction Stop)
            Write-AuditLog "To                  : $To"
            Write-AuditLog "From                : $FromAddress"
            Write-AuditLog "Attachments Sent    : $(($Message.message.attachments).Count)"
            Write-AuditLog -EndFunction
        }
        catch {
            throw
        }
    } # End Region End
}
