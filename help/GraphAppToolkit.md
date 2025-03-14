---
Module Name: GraphAppToolkit
Module Guid: b5426317-5612-4483-b664-beafc448bc2f
Download Help Link: {{ Update Download Link }}
Help Version: {{ Please enter version of help manually (X.X.X.X) format }}
Locale: en-US
---

# GraphAppToolkit Module
## Description
The GraphAppToolkit module provides a collection of PowerShell functions to automate the management of Azure AD (Entra ID) application registrations. It streamlines the deployment of Microsoft Graph-powered applications, focusing on app-only authentication using certificates, secure credential storage, and operational automation. This module is designed to: - Enable certificate-based authentication for Microsoft Graph applications. - Simplify email sending from service principals. - Automate Intune (MEM) policy management . - Deploy M365 audit apps with read-write permissions. - Securely manage mail-enabled security groups for restricted send scenarios. GraphAppToolkit is ideal for IT admins, security engineers, and DevOps teams managing Microsoft 365 and Entra ID workloads.

## GraphAppToolkit Cmdlets
### [New-MailEnabledSendingGroup](New-MailEnabledSendingGroup)
Creates or retrieves a mail-enabled security group with a custom or default domain.

### [Publish-TkEmailApp](Publish-TkEmailApp)
Deploys a new Microsoft Graph Email app and associates it with a certificate for app-only authentication.

### [Publish-TkM365AuditApp](Publish-TkM365AuditApp)
Publishes (creates) a new M365 Audit App registration in Entra ID (Azure AD) with a specified certificate.

### [Publish-TkMemPolicyManagerApp](Publish-TkMemPolicyManagerApp)
Publishes a new MEM (Intune) Policy Manager App in Azure AD with read-only or read-write permissions.

### [Send-TkEmailAppMessage](Send-TkEmailAppMessage)
Sends an email using the Microsoft Graph API, either by retrieving app credentials from a local vault
or by specifying them manually.

