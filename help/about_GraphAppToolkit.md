# GraphAppToolkit
## about_GraphAppToolkit

# SHORT DESCRIPTION

GraphAppToolkit is a PowerShell module that streamlines the creation, configuration, and management of Microsoft Entra ID (Azure AD) applications for various scenarios, such as sending emails through Microsoft Graph, performing M365 tenant audits, and managing Intune (MEM) policies.

# LONG DESCRIPTION

GraphAppToolkit provides a set of commands (both public and private) that help you:

- Create and configure Azure AD app registrations with certificate-based authentication.
- Grant the necessary Graph permissions (read-only or read-write) for each scenario.
- Securely store and retrieve app credentials in local vaults (via SecretManagement).
- Send emails, manage policy assignments, and perform audits in an automated fashion.

The toolkit is particularly useful for administrators who want a repeatable, scriptable process for deploying or managing specialized Azure AD apps (for example, an email-sending app, a read-only M365 audit app, or an Intune policy manager).

## Optional Subtopics

- **Publishing Graph Email Apps**
  Functions like `Publish-TkEmailApp` create an Azure AD app that can send mail as a particular user or group.  
- **M365 Audit Apps**  
  The `Publish-TkM365AuditApp` function sets up a read-only or read-write app to perform audits across M365 workloads (Exchange, SharePoint, Teams, etc.).  
- **MEM Policy Manager Apps**  
  The `Publish-TkMemPolicyManagerApp` function configures an Intune (MEM) app with the necessary permissions to manage devices and policies.


# EXAMPLES

```powershell
# Example 1: Publish a new Graph Email App
Publish-TkEmailApp -AppPrefix "ABC" `
    -AuthorizedSenderUserName "jdoe@example.com" `
    -MailEnabledSendingGroup "GraphAPIMailGroup@example.com" `
    -CertThumbprint "AABBCCDDEEFF11223344556677889900"

# Example 2: Send an email with attachments using the newly created app
Send-TkEmailAppMessage -AppName "CN=ABC-AuditGraphEmail-AD.EXAMPLE.COM-As-jdoe" `
    -To "recipient@example.com" `
    -FromAddress "jdoe@example.com" `
    -Subject "Hello from Graph" `
    -EmailBody "This is a test email from the GraphAppToolkit." `
    -AttachmentPath "C:\Reports\WeeklyReport.xlsx"
```

# NOTE

This module assumes you have already or will configure certificate-based authentication in your local Cert:\CurrentUser\My store. If the module cannot find the specified certificate thumbprint, the commands will throw an error.

# TROUBLESHOOTING NOTE

If you receive token acquisition or 401 (Unauthorized) errors, ensure that admin consent has been granted for the created Azure AD app.
If the local vault secret is missing or corrupted, re-run the corresponding Publish-* function to regenerate or update your app credentials.


# SEE ALSO

<https://learn.microsoft.com/en-us/graph/>
<https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/?view=ps-modules>
<https://github.com/AzureAD/MSAL.PS>
<https://learn.microsoft.com/en-us/entra/identity/>

# KEYWORDS

-GraphAppToolkit
-Azure AD
-Microsoft Graph
-Certificate-Based Auth
-Intune (MEM)
-Email App
-Audit App
-PowerShell
