---
external help file: GraphAppToolkit-help.xml
Module Name: GraphAppToolkit
online version:
schema: 2.0.0
---

# Publish-TkEmailApp

## SYNOPSIS
Deploys a new Microsoft Graph Email app and associates it with a certificate for app-only authentication.

## SYNTAX

```
Publish-TkEmailApp [-AppPrefix] <String> [[-CertThumbprint] <String>] [[-KeyExportPolicy] <String>]
 [-AuthorizedSenderUserName] <String> [-MailEnabledSendingGroup] <String> [[-VaultName] <String>]
 [-OverwriteVaultSecret] [-ReturnParamSplat] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
This cmdlet deploys a new Microsoft Graph Email app and associates it with a certificate for
app-only authentication.
It requires an AppPrefix for the app, an optional CertThumbprint, an
AuthorizedSenderUserName, and a MailEnabledSendingGroup.
Additionally, you can specify a
KeyExportPolicy for the certificate, control how secrets are stored via VaultName and OverwriteVaultSecret,
and optionally return a parameter splat instead of a PSCustomObject.

## EXAMPLES

### EXAMPLE 1
```
Publish-TkEmailApp -AppPrefix "ABC" -AuthorizedSenderUserName "jdoe@example.com" -MailEnabledSendingGroup "GraphAPIMailGroup@example.com" -CertThumbprint "AABBCCDDEEFF11223344556677889900"
```

## PARAMETERS

### -AppPrefix
A unique prefix for the Graph Email App to initialize.
Ensure it is used consistently for
grouping purposes (2-4 alphanumeric characters).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertThumbprint
An optional parameter indicating the thumbprint of the certificate to be retrieved.
If not
specified, a self-signed certificate will be generated.

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
Specifies the key export policy for the newly created certificate.
Valid values are
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

### -AuthorizedSenderUserName
The username of the authorized sender.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MailEnabledSendingGroup
The mail-enabled group to which the sender belongs.
This will be used to assign
app policy restrictions.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VaultName
If specified, the name of the vault to store the app's credentials.
Otherwise,
defaults to 'GraphEmailAppLocalStore'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: GraphEmailAppLocalStore
Accept pipeline input: False
Accept wildcard characters: False
```

### -OverwriteVaultSecret
If specified, the function overwrites an existing secret in the vault if it
already exists.

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
If specified, returns the parameter splat for use in other functions instead
of the PSCustomObject.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
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

### None
## OUTPUTS

### By default, returns a PSCustomObject containing details such as AppId, CertThumbprint,
### TenantID, and CertExpires. If -ReturnParamSplat is specified, returns the parameter
### splat instead.
## NOTES
This cmdlet requires that the user running the cmdlet have the necessary permissions to
create the app and connect to Exchange Online.
In addition, a mail-enabled security group
must already exist in Exchange Online for the MailEnabledSendingGroup parameter.

Permissions required:
    'Application.ReadWrite.All',
    'DelegatedPermissionGrant.ReadWrite.All',
    'Directory.ReadWrite.All',
    'RoleManagement.ReadWrite.Directory'

## RELATED LINKS
