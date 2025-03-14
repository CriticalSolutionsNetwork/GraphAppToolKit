---
external help file: GraphAppToolkit-help.xml
Module Name: GraphAppToolkit
online version:
schema: 2.0.0
---

# Publish-TkEmailApp

## SYNOPSIS
Publishes a new or existing Graph Email App with specified configurations.

## SYNTAX

### CreateNewApp (Default)
```
Publish-TkEmailApp [-AppPrefix <String>] -AuthorizedSenderUserName <String> -MailEnabledSendingGroup <String>
 [-CertPrefix <String>] [-CertThumbprint <String>] [-KeyExportPolicy <String>] [-VaultName <String>]
 [-OverwriteVaultSecret] [-ReturnParamSplat] [-DoNotUseDomainSuffix] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### UseExistingApp
```
Publish-TkEmailApp -ExistingAppObjectId <String> -CertPrefix <String> [-CertThumbprint <String>]
 [-KeyExportPolicy <String>] [-VaultName <String>] [-OverwriteVaultSecret] [-ReturnParamSplat]
 [-DoNotUseDomainSuffix] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Publish-TkEmailApp function creates or configures a Graph Email App in Azure AD.
It supports two scenarios:
1.
Creating a new app with specified parameters.
2.
Using an existing app and attaching a certificate to it.

## EXAMPLES

### EXAMPLE 1
```
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
```

### EXAMPLE 2
```
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
```

## PARAMETERS

### -AppPrefix
The prefix used to initialize the Graph Email App.
Must be 2-4 characters, letters, and numbers only.
Default is 'Gtk'.

```yaml
Type: String
Parameter Sets: CreateNewApp
Aliases:

Required: False
Position: Named
Default value: Gtk
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuthorizedSenderUserName
The username of the authorized sender.
Must be a valid email address.

```yaml
Type: String
Parameter Sets: CreateNewApp
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MailEnabledSendingGroup
The mail-enabled security group.
Must be a valid email address.

```yaml
Type: String
Parameter Sets: CreateNewApp
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExistingAppObjectId
The AppId of the existing App Registration to which you want to attach a certificate.
Must be a valid GUID.

```yaml
Type: String
Parameter Sets: UseExistingApp
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertPrefix
Prefix to add to the certificate subject for the existing app.

```yaml
Type: String
Parameter Sets: CreateNewApp
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: UseExistingApp
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertThumbprint
The thumbprint of the certificate to be retrieved.
Must be a valid 40-character hexadecimal string.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyExportPolicy
Key export policy for the certificate.
Valid values are 'Exportable' and 'NonExportable'.
Default is 'NonExportable'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: NonExportable
Accept pipeline input: False
Accept wildcard characters: False
```

### -VaultName
If specified, use a custom vault name.
Otherwise, use the default 'GraphEmailAppLocalStore'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: GraphEmailAppLocalStore
Accept pipeline input: False
Accept wildcard characters: False
```

### -OverwriteVaultSecret
If specified, overwrite the vault secret if it already exists.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReturnParamSplat
If specified, return the parameter splat for use in other functions.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotUseDomainSuffix
Switch to add session domain suffix to the app name.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
This cmdlet requires that the user running the cmdlet have the necessary permissions to create the app and connect to Exchange Online.

## RELATED LINKS
