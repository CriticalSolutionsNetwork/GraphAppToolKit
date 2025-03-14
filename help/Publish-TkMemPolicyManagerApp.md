---
external help file: GraphAppToolkit-help.xml
Module Name: GraphAppToolkit
online version:
schema: 2.0.0
---

# Publish-TkMemPolicyManagerApp

## SYNOPSIS
Publishes a new MEM (Intune) Policy Manager App in Azure AD with read-only or read-write permissions.

## SYNTAX

```
Publish-TkMemPolicyManagerApp [-AppPrefix] <String> [[-CertThumbprint] <String>] [[-KeyExportPolicy] <String>]
 [[-VaultName] <String>] [-OverwriteVaultSecret] [-ReadWrite] [-ReturnParamSplat]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Publish-TkMemPolicyManagerApp function creates an Azure AD application
intended for managing Microsoft Endpoint Manager (MEM/Intune) policies.
It optionally creates or retrieves a certificate, configures the necessary
Microsoft Graph permissions for read-only or read-write access, and stores
the resulting app credentials in a SecretManagement vault.

## EXAMPLES

### EXAMPLE 1
```
Publish-TkMemPolicyManagerApp -AppPrefix "CORP" -ReadWrite
```

Creates a new MEM Policy Manager App with read-write permissions, retrieves or
creates a certificate, and stores the credentials in the default vault.

## PARAMETERS

### -AppPrefix
A 2-4 character prefix used to build the application name (e.g., CORP, MSN).
This helps uniquely identify the app in Azure AD.

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
The thumbprint of an existing certificate in the current user's certificate
store.
If omitted, a new self-signed certificate is created.

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
Specifies whether the newly created certificate is 'Exportable' or 'NonExportable'.
Defaults to 'NonExportable' if not specified.

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
The name of the SecretManagement vault in which to store the app credentials.
Defaults to 'MemPolicyManagerLocalStore'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: MemPolicyManagerLocalStore
Accept pipeline input: False
Accept wildcard characters: False
```

### -OverwriteVaultSecret
If specified, overwrites any existing secret of the same name in the vault.

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

### -ReadWrite
If specified, grants read-write MEM/Intune permissions.
Otherwise, read-only
permissions are granted.

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
If specified, returns a parameter splat string for use in other functions.
Otherwise, returns a PSCustomObject containing the app details.

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

### By default, returns a PSCustomObject (TkMemPolicyManagerAppParams) with details of the newly created
### app (AppId, certificate thumbprint, tenant ID, etc.). If -ReturnParamSplat is used, returns a parameter
### splat string.
## NOTES
This function requires the Microsoft.Graph module for application creation and
the user must have permissions in Azure AD to register and grant permissions
to the application.
After creation, admin consent may be needed to finalize
the permission grants.

    Permissions required:
        'Application.ReadWrite.All',
        'DelegatedPermissionGrant.ReadWrite.All',
        'Directory.ReadWrite.All',
        'RoleManagement.ReadWrite.Directory'

## RELATED LINKS
