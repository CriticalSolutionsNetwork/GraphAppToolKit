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

### CreateNewApp (Default)
```
Publish-TkEmailApp [-AppPrefix <String>] -AuthorizedSenderUserName <String> -MailEnabledSendingGroup <String>
 [-CertPrefix <String>] [-CertThumbprint <String>] [-KeyExportPolicy <String>] [-VaultName <String>]
 [-OverwriteVaultSecret] [-ReturnParamSplat] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### UseExistingApp
```
Publish-TkEmailApp -ExistingAppObjectId <String> -CertPrefix <String> [-CertThumbprint <String>]
 [-KeyExportPolicy <String>] [-VaultName <String>] [-OverwriteVaultSecret] [-ReturnParamSplat]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
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
Parameter Sets: CreateNewApp
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuthorizedSenderUserName
The username of the authorized sender.

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
The mail-enabled group to which the sender belongs.
This will be used to assign
app policy restrictions.

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
The AppId of the existing App Registration to which you want to attach a certificate. Must be a valid GUID.

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
An optional parameter indicating the thumbprint of the certificate to be retrieved.
If not
specified, a self-signed certificate will be generated.

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
Specifies the key export policy for the newly created certificate.
Valid values are
'Exportable' or 'NonExportable'.
Defaults to 'NonExportable'.

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
If specified, the name of the vault to store the app's credentials.
Otherwise,
defaults to 'GraphEmailAppLocalStore'.

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
