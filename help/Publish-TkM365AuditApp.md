---
external help file: GraphAppToolkit-help.xml
Module Name: GraphAppToolkit
online version:
schema: 2.0.0
---

# Publish-TkM365AuditApp

## SYNOPSIS
Publishes (creates) a new M365 Audit App registration in Entra ID (Azure AD) with a specified certificate.

## SYNTAX

```
Publish-TkM365AuditApp [[-AppPrefix] <String>] [[-CertThumbprint] <String>] [[-KeyExportPolicy] <String>]
 [[-VaultName] <String>] [-OverwriteVaultSecret] [-ReturnParamSplat] [-DoNotUseDomainSuffix]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Publish-TkM365AuditApp function creates a new Azure AD application used for M365 auditing.
It connects to Microsoft Graph, gathers the required permissions for SharePoint and Exchange,
and optionally creates a self-signed certificate if no thumbprint is provided.
It also assigns
the application to the Exchange Administrator and Global Reader roles.
By default, the newly
created application details are stored as a secret in the specified SecretManagement vault.

## EXAMPLES

### EXAMPLE 1
```
Publish-TkM365AuditApp -AppPrefix "CS12" -ReturnParamSplat
Creates a new M365 Audit App with the prefix "CS12", returns a parameter splat, and stores
the credentials in the default vault.
```

## PARAMETERS

### -AppPrefix
A short prefix (2-4 alphanumeric characters) used to build the app name.
Defaults to "Gtk"
if not specified.
Example app name: GraphToolKit-MSN-GraphApp-MyDomain-As-helpDesk

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Gtk
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertThumbprint
The thumbprint of an existing certificate in the current user's certificate store.
If not
provided, a new self-signed certificate is created.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyExportPolicy
Specifies whether the newly created certificate (if no thumbprint is provided) is
'Exportable' or 'NonExportable'.
Defaults to 'NonExportable'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: NonExportable
Accept pipeline input: False
Accept wildcard characters: False
```

### -VaultName
The SecretManagement vault name in which to store the app credentials.
Defaults to
"M365AuditAppLocalStore" if not specified.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: M365AuditAppLocalStore
Accept pipeline input: False
Accept wildcard characters: False
```

### -OverwriteVaultSecret
If specified, overwrites an existing secret in the specified vault if it already exists.

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
If specified, returns a parameter splat string for use in other functions, instead of the
default PSCustomObject containing the app details.

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
If specified, does not append the domain suffix to the app name.

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

### None. This function does not accept pipeline input.
## OUTPUTS

### By default, returns a PSCustomObject with details of the new app (AppId, ObjectId, TenantId,
### certificate thumbprint, expiration, etc.). If -ReturnParamSplat is used, returns a parameter
### splat string.
## NOTES
Requires the Microsoft.Graph and ExchangeOnlineManagement modules for app creation and
role assignment.
The user must have sufficient privileges to create and manage applications
in Azure AD, and to assign roles.
After creation, admin consent may be required for the
assigned permissions.
Permissions required for app registration:
    'Application.ReadWrite.All',
    'DelegatedPermissionGrant.ReadWrite.All',
    'Directory.ReadWrite.All',
    'RoleManagement.ReadWrite.Directory'

Permissions granted to the app:
(Exchange Administrator and Global Reader Roles are also added to the service principal.)
    'AppCatalog.ReadWrite.All',
    'Channel.Delete.All',
    'ChannelMember.ReadWrite.All',
    'ChannelSettings.ReadWrite.All',
    'Directory.Read.All',
    'Group.ReadWrite.All',
    'Organization.Read.All',
    'Policy.Read.All',
    'Domain.Read.All',
    'TeamSettings.ReadWrite.All',
    'User.Read.All',
    'Sites.Read.All',
    'Sites.FullControl.All',
    'Exchange.ManageAsApp'

## RELATED LINKS
