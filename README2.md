# GraphAppToolkit Module
## New-MailEnabledSendingGroup
### Synopsis
Creates or retrieves a mail-enabled security group with a custom or default domain.
### Syntax
```powershell

New-MailEnabledSendingGroup -Name <String> [-Alias <String>] -PrimarySmtpAddress <String> [-WhatIf] [-Confirm] [<CommonParameters>]

New-MailEnabledSendingGroup -Name <String> [-Alias <String>] -DefaultDomain <String> [-WhatIf] [-Confirm] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Name</nobr> |  | The name of the mail-enabled security group to create or retrieve. This is also used as the alias if no separate Alias parameter is provided. | true | false |  |
| <nobr>Alias</nobr> |  | An optional alias for the group. If omitted, the group name is used as the alias. | false | false |  |
| <nobr>PrimarySmtpAddress</nobr> |  | \(CustomDomain parameter set\) The full SMTP address for the group \(e.g. "MyGroup@contoso.com"\). This parameter is mandatory when using the 'CustomDomain' parameter set. | true | false |  |
| <nobr>DefaultDomain</nobr> |  | \(DefaultDomain parameter set\) The domain portion to be appended to the group alias \(e.g. "Alias@DefaultDomain"\). This parameter is mandatory when using the 'DefaultDomain' parameter set. | true | false |  |
| <nobr>WhatIf</nobr> | wi |  | false | false |  |
| <nobr>Confirm</nobr> | cf |  | false | false |  |
### Inputs
 - None. This function does not accept pipeline input.

### Outputs
 - Microsoft.Exchange.Data.Directory.Management.DistributionGroup Returns the newly created or existing mail-enabled security group object.

### Note
- Requires connectivity to Exchange Online \(Connect-TkMsService -ExchangeOnline\). - The caller must have sufficient privileges to create or modify distribution groups. - DefaultParameterSetName = 'CustomDomain'.

### Examples
**EXAMPLE 1**
```powershell
New-MailEnabledSendingGroup -Name "SecureSenders" -DefaultDomain "contoso.com"
Creates a new mail-enabled security group named "SecureSenders" with a primary SMTP address
of SecureSenders@contoso.com.
```


**EXAMPLE 2**
```powershell
New-MailEnabledSendingGroup -Name "SecureSenders" -Alias "Senders" -PrimarySmtpAddress "Senders@customdomain.org"
Creates a new mail-enabled security group named "SecureSenders" with an alias "Senders"
and a primary SMTP address of Senders@customdomain.org.
```


## Publish-TkEmailApp
### Synopsis
Publishes a new or existing Graph Email App with specified configurations.
### Syntax
```powershell

Publish-TkEmailApp [-AppPrefix <String>] -AuthorizedSenderUserName <String> -MailEnabledSendingGroup <String> [-CertPrefix <String>] [-CertThumbprint <String>] [-KeyExportPolicy <String>] [-VaultName <String>] [-OverwriteVaultSecret] [-ReturnParamSplat] [<CommonParameters>]

Publish-TkEmailApp -ExistingAppObjectId <String> -CertPrefix <String> [-CertThumbprint <String>] [-KeyExportPolicy <String>] [-VaultName <String>] [-OverwriteVaultSecret] [-ReturnParamSplat] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>AppPrefix</nobr> |  | The prefix used to initialize the Graph Email App. Must be 2-4 characters, letters, and numbers only. Default is 'Gtk'. | false | false | Gtk |
| <nobr>AuthorizedSenderUserName</nobr> |  | The username of the authorized sender. Must be a valid email address. | true | false |  |
| <nobr>MailEnabledSendingGroup</nobr> |  | The mail-enabled security group. Must be a valid email address. | true | false |  |
| <nobr>ExistingAppObjectId</nobr> |  | The AppId of the existing App Registration to which you want to attach a certificate. Must be a valid GUID. | true | false |  |
| <nobr>CertPrefix</nobr> |  | Prefix to add to the certificate subject for the existing app. | false | false |  |
| <nobr>CertThumbprint</nobr> |  | The thumbprint of the certificate to be retrieved. Must be a valid 40-character hexadecimal string. | false | false |  |
| <nobr>KeyExportPolicy</nobr> |  | Key export policy for the certificate. Valid values are 'Exportable' and 'NonExportable'. Default is 'NonExportable'. | false | false | NonExportable |
| <nobr>VaultName</nobr> |  | If specified, use a custom vault name. Otherwise, use the default 'GraphEmailAppLocalStore'. | false | false | GraphEmailAppLocalStore |
| <nobr>OverwriteVaultSecret</nobr> |  | If specified, overwrite the vault secret if it already exists. | false | false | False |
| <nobr>ReturnParamSplat</nobr> |  | If specified, return the parameter splat for use in other functions. | false | false | False |
### Note
This cmdlet requires that the user running the cmdlet have the necessary permissions to create the app and connect to Exchange Online. Permissions required: - 'Application.ReadWrite.All' - 'DelegatedPermissionGrant.ReadWrite.All' - 'Directory.ReadWrite.All' - 'RoleManagement.ReadWrite.Directory'

### Examples
**EXAMPLE 1**
```powershell
Publish-TkEmailApp -AppPrefix 'Gtk' -AuthorizedSenderUserName 'user@example.com' -MailEnabledSendingGroup 'group@example.com'
```
Creates a new Graph Email App with the specified parameters.

**EXAMPLE 2**
```powershell
Publish-TkEmailApp -ExistingAppObjectId '12345678-1234-1234-1234-1234567890ab' -CertPrefix 'Cert'
```
Uses an existing app and attaches a certificate with the specified prefix.

## Publish-TkM365AuditApp
### Synopsis
Publishes \(creates\) a new M365 Audit App registration in Entra ID \(Azure AD\) with a specified certificate.
### Syntax
```powershell

Publish-TkM365AuditApp [[-AppPrefix] <String>] [[-CertThumbprint] <String>] [[-KeyExportPolicy] <String>] [[-VaultName] <String>] [-OverwriteVaultSecret] [-ReturnParamSplat] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>AppPrefix</nobr> |  | A short prefix \(2-4 alphanumeric characters\) used to build the app name. Defaults to "Gtk" if not specified. Example app name: GraphToolKit-MSN-GraphApp-MyDomain-As-helpDesk | false | false | Gtk |
| <nobr>CertThumbprint</nobr> |  | The thumbprint of an existing certificate in the current user's certificate store. If not provided, a new self-signed certificate is created. | false | false |  |
| <nobr>KeyExportPolicy</nobr> |  | Specifies whether the newly created certificate \(if no thumbprint is provided\) is 'Exportable' or 'NonExportable'. Defaults to 'NonExportable'. | false | false | NonExportable |
| <nobr>VaultName</nobr> |  | The SecretManagement vault name in which to store the app credentials. Defaults to "M365AuditAppLocalStore" if not specified. | false | false | M365AuditAppLocalStore |
| <nobr>OverwriteVaultSecret</nobr> |  | If specified, overwrites an existing secret in the specified vault if it already exists. | false | false | False |
| <nobr>ReturnParamSplat</nobr> |  | If specified, returns a parameter splat string for use in other functions, instead of the default PSCustomObject containing the app details. | false | false | False |
### Inputs
 - None. This function does not accept pipeline input.

### Outputs
 - By default, returns a PSCustomObject with details of the new app \(AppId, ObjectId, TenantId, certificate thumbprint, expiration, etc.\). If -ReturnParamSplat is used, returns a parameter splat string.

### Note
Requires the Microsoft.Graph and ExchangeOnlineManagement modules for app creation and role assignment. The user must have sufficient privileges to create and manage applications in Azure AD, and to assign roles. After creation, admin consent may be required for the assigned permissions. Permissions required: 'Application.ReadWrite.All', 'DelegatedPermissionGrant.ReadWrite.All', 'Directory.ReadWrite.All', 'RoleManagement.ReadWrite.Directory'

### Examples
**EXAMPLE 1**
```powershell
Publish-TkM365AuditApp -AppPrefix "CS12" -ReturnParamSplat
Creates a new M365 Audit App with the prefix "CS12", returns a parameter splat, and stores
the credentials in the default vault.
```


## Publish-TkMemPolicyManagerApp
### Synopsis
Publishes a new MEM \(Intune\) Policy Manager App in Azure AD with read-only or read-write permissions.
### Syntax
```powershell

Publish-TkMemPolicyManagerApp [-AppPrefix] <String> [[-CertThumbprint] <String>] [[-KeyExportPolicy] <String>] [[-VaultName] <String>] [-OverwriteVaultSecret] [-ReadWrite] [-ReturnParamSplat] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>AppPrefix</nobr> |  | A 2-4 character prefix used to build the application name \(e.g., CORP, MSN\). This helps uniquely identify the app in Azure AD. | true | false |  |
| <nobr>CertThumbprint</nobr> |  | The thumbprint of an existing certificate in the current user's certificate store. If omitted, a new self-signed certificate is created. | false | false |  |
| <nobr>KeyExportPolicy</nobr> |  | Specifies whether the newly created certificate is 'Exportable' or 'NonExportable'. Defaults to 'NonExportable' if not specified. | false | false | NonExportable |
| <nobr>VaultName</nobr> |  | The name of the SecretManagement vault in which to store the app credentials. Defaults to 'MemPolicyManagerLocalStore'. | false | false | MemPolicyManagerLocalStore |
| <nobr>OverwriteVaultSecret</nobr> |  | If specified, overwrites any existing secret of the same name in the vault. | false | false | False |
| <nobr>ReadWrite</nobr> |  | If specified, grants read-write MEM/Intune permissions. Otherwise, read-only permissions are granted. | false | false | False |
| <nobr>ReturnParamSplat</nobr> |  | If specified, returns a parameter splat string for use in other functions. Otherwise, returns a PSCustomObject containing the app details. | false | false | False |
### Inputs
 - None. This function does not accept pipeline input.

### Outputs
 - By default, returns a PSCustomObject \(TkMemPolicyManagerAppParams\) with details of the newly created app \(AppId, certificate thumbprint, tenant ID, etc.\). If -ReturnParamSplat is used, returns a parameter splat string.

### Note
This function requires the Microsoft.Graph module for application creation and the user must have permissions in Azure AD to register and grant permissions to the application. After creation, admin consent may be needed to finalize the permission grants. Permissions required: 'Application.ReadWrite.All', 'DelegatedPermissionGrant.ReadWrite.All', 'Directory.ReadWrite.All', 'RoleManagement.ReadWrite.Directory'

### Examples
**EXAMPLE 1**
```powershell
Publish-TkMemPolicyManagerApp -AppPrefix "CORP" -ReadWrite
Creates a new MEM Policy Manager App with read-write permissions, retrieves or
creates a certificate, and stores the credentials in the default vault.
```


## Send-TkEmailAppMessage
### Synopsis
Sends an email using the Microsoft Graph API, either by retrieving app credentials from a local vault or by specifying them manually.
### Syntax
```powershell

Send-TkEmailAppMessage -AppName <String> -To <String> -FromAddress <String> -Subject <String> -EmailBody <String> [-AttachmentPath <String[]>] [-VaultName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]

Send-TkEmailAppMessage -AppId <String> -TenantId <String> -CertThumbprint <String> -To <String> -FromAddress <String> -Subject <String> -EmailBody <String> [-AttachmentPath <String[]>] [-WhatIf] [-Confirm] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>AppName</nobr> |  | \\[Vault Parameter Set Only\\] The name of the pre-created Microsoft Graph Email App \(stored in GraphEmailAppLocalStore\). Used only if the 'Vault' parameter set is chosen. The function retrieves the AppId, TenantId, and certificate thumbprint from the vault entry. | true | false |  |
| <nobr>AppId</nobr> |  | \\[Manual Parameter Set Only\\] The Azure AD application \(client\) ID to use for sending the email. Must be used together with TenantId and CertThumbprint in the 'Manual' parameter set. | true | false |  |
| <nobr>TenantId</nobr> |  | \\[Manual Parameter Set Only\\] The Azure AD tenant ID \(GUID or domain name\). Must be used together with AppId and CertThumbprint in the 'Manual' parameter set. | true | false |  |
| <nobr>CertThumbprint</nobr> |  | \\[Manual Parameter Set Only\\] The certificate thumbprint \(in Cert:\\CurrentUser\\My\) used for authenticating as the Azure AD app. Must be used together with AppId and TenantId in the 'Manual' parameter set. | true | false |  |
| <nobr>To</nobr> |  | The email address of the recipient. | true | false |  |
| <nobr>FromAddress</nobr> |  | The email address of the sender who is authorized to send email as configured in the Graph Email App. | true | false |  |
| <nobr>Subject</nobr> |  | The subject line of the email. | true | false |  |
| <nobr>EmailBody</nobr> |  | The body text of the email. | true | false |  |
| <nobr>AttachmentPath</nobr> |  | An array of file paths for any attachments to include in the email. Each path must exist as a leaf file. | false | false |  |
| <nobr>VaultName</nobr> |  | \\[Vault Parameter Set Only\\] The name of the vault to retrieve the GraphEmailApp object. Default is 'GraphEmailAppLocalStore'. | false | false | GraphEmailAppLocalStore |
| <nobr>WhatIf</nobr> | wi |  | false | false |  |
| <nobr>Confirm</nobr> | cf |  | false | false |  |
### Note
- This function requires the Microsoft.Graph, SecretManagement, SecretManagement.JustinGrote.CredMan, and MSAL.PS modules to be installed \(handled automatically via Initialize-TkModuleEnv\). - For the 'Vault' parameter set, the local vault secret must store JSON properties including AppId, TenantID, and CertThumbprint. - Refer to https://learn.microsoft.com/en-us/graph/outlook-send-mail for details on sending mail via Microsoft Graph.

### Examples
**EXAMPLE 1**
```powershell
# Using the 'Vault' parameter set
Send-TkEmailAppMessage -AppName "GraphEmailApp" -To "recipient@example.com" -FromAddress "sender@example.com" `
-Subject "Test Email" -EmailBody "This is a test email."
Retrieves the app's credentials (AppId, TenantId, CertThumbprint) from the local vault under the
secret name "GraphEmailApp" and sends an email.
```


**EXAMPLE 2**
```powershell
# Using the 'Manual' parameter set
Send-TkEmailAppMessage -AppId "00000000-1111-2222-3333-444444444444" -TenantId "contoso.onmicrosoft.com" `
-CertThumbprint "AABBCCDDEEFF11223344556677889900" -To "recipient@example.com" -FromAddress "sender@example.com" `
-Subject "Manual Email" -EmailBody "Hello from Manual!"
Uses the provided AppId, TenantId, and CertThumbprint directly (no vault) to obtain a token and send an email.
```


