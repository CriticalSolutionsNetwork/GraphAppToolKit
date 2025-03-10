# GraphAppToolkit Module

## Summary

The **GraphAppToolkit** module provides a set of functions and classes to quickly create, configure, and manage Azure AD (Entra) application registrations for various Microsoft 365 scenarios. It focuses on app-only authentication with certificates, storing credentials securely in SecretManagement vaults, and simplifying tasks like sending emails from a service principal, managing mail-enabled groups, and publishing specialized apps for M365 auditing or MEM policy management.

## Help Documentation

In addition to in-line PowerShell help (`Get-Help <FunctionName> -Full`), you can refer to the `about_GraphAppToolkit.help.txt` file (if included in the module) or any published documentation for more details on usage.

## Public Functions

The following Public Functions are exposed by the **GraphAppToolkit** module:

- **New-MailEnabledSendingGroup**
  Creates a new mail-enabled security group in Exchange Online for restricted send scenarios.

- **Publish-TkEmailApp**
  Publishes a Microsoft Graph Email App with certificate-based authentication and optionally restricts sending to a specific mail-enabled group.

- **Publish-TkM365AuditApp**
  Publishes an Azure AD application with read-only or read-write sets of Graph/SharePoint/Exchange permissions for auditing or compliance tasks.

- **Publish-TkMemPolicyManagerApp**
  Publishes an Azure AD application for MEM (Intune) policy management, supporting read-only or read-write permissions.

- **Send-TkEmailAppMessage**
  Sends an email using a previously published email app’s certificate-based authentication (no user mailbox required).

## Private Functions

The following Private Functions support the module’s internal processes and are not exported:

- **Connect-TkMsService**
- **ConvertTo-ParameterSplat**
- **Initialize-TkAppAuthCertificate**
- **Initialize-TkAppSpRegistration**
- **Initialize-TkModuleEnv**
- **New-TkAppName**
- **New-TkAppRegistration**
- **New-TkExchangeEmailAppPolicy**
- **New-TkRequiredResourcePermissionObject**
- **Set-TkJsonSecret**
- **Test-IsAdmin**
- **Write-AuditLog**

These private functions handle core logic like certificate generation, connecting to Microsoft services, app registration, secret storage, and logging.

---

## Examples

### Example 1: Creating a Mail-Enabled Security Group

```powershell
$DefaultDomain = 'contoso.com'
$MailEnabledSendingGroupToCreate = "CTSO-GraphAPIMail"
# Creates a mail-enabled security group named "MySenders" using a default domain
$group = New-MailEnabledSendingGroup -Name $MailEnabledSendingGroupToCreate -DefaultDomain $DefaultDomain
```

### Example 2: Publishing a Graph Email App

# Publishes an email app restricted to a mail-enabled group

```powershell
# Uses Group Variable from Example 1
$LicensedUserToSendAs = 'helpdesk@contoso.com'
$TwoToFourLetterCompanyAbbreviation = "CTSO"
Publish-TkEmailApp `
    -AppPrefix $TwoToFourLetterCompanyAbbreviation `
    -AuthorizedSenderUserName $LicensedUserToSendAs `
    -MailEnabledSendingGroup $group.PrimarySmtpAddress `
    -ReturnParamSplat
```

### Example 3: Sending Email from the Published App

```powershell
# Param Splat returned from Example 2 will have all values populated
$params = @{
    AppId = "your-app-id"
    Id = "your-app-object-id"
    AppName = "CN=YourAppName"
    AppRestrictedSendGroup = "YourRestrictedSendGroup@domain.com"
    CertExpires = "yyyy-MM-dd HH:mm:ss"
    CertThumbprint = "your-cert-thumbprint"
    ConsentUrl = "https://login.microsoftonline.com/your-tenant-id/adminconsent?client_id=your-app-id"
    DefaultDomain = 'contoso.com'
    SendAsUser = 'helpdesk'
    SendAsUserEmail = 'helpdesk@contoso.com'
    TenantID = "your-tenant-id"
}
# Sends an email using a previously published TkEmailApp
Send-TkEmailAppMessage `
    -AppName $params.AppName `
    -To 'user@contoso.com' `
    -FromAddress $params.SendAsUserEmail `
    -Subject 'Test Email' `
    -EmailBody 'This is a test email.' `
    -AttachmentPath 'C:\temp\attachmentFile.zip', 'C:\temp\anotherAttachmentFile.zip' `
    -ReturnParamSplat

# Send using manual parameters
$AppId = "00000000-1111-2222-3333-444444444444"
$TenantId = "00000000-1111-2222-3333-444444444444"
$CertThumbprint = "AABBCCDDEEFF11223344556677889900"
$To = "user@contoso.com"
$FromAddress = 'helpdesk@contoso.com'
Send-TkEmailAppMessage `
    -AppId $AppId `
    -TenantId $TenantId  `
    -CertThumbprint $CertThumbprint `
    -To $To `
    -FromAddress $FromAddress `
    -Subject "Manual Email" `
    -EmailBody "Hello from Manual!"
```

### Example 4: Publishing an M365 Audit App

```powershell
# Publishes a read-only M365 audit app (e.g., for directory or device management auditing)
Publish-TkM365AuditApp -AppPrefix "CSN" -CertThumbprint "FACEBEEFBEEFAABBCCDDEEFF11223344"
```

### Example 5: Publishing a MEM Policy Manager App

```powershell
# Publishes a read-write MEM Policy Manager app with a self-signed cert
Publish-TkMemPolicyManagerApp -AppPrefix "MEM" -ReadWrite
```
