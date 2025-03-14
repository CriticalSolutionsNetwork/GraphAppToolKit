---
external help file: GraphAppToolkit-help.xml
Module Name: GraphAppToolkit
online version:
schema: 2.0.0
---

# New-MailEnabledSendingGroup

## SYNOPSIS
Creates or retrieves a mail-enabled security group with a custom or default domain.

## SYNTAX

### CustomDomain (Default)
```
New-MailEnabledSendingGroup -Name <String> [-Alias <String>] -PrimarySmtpAddress <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### DefaultDomain
```
New-MailEnabledSendingGroup -Name <String> [-Alias <String>] -DefaultDomain <String>
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-MailEnabledSendingGroup function ensures that a mail-enabled security
group is available for restricting email sending.
It connects to Exchange Online
to verify if a group of the specified name already exists.
If the existing group
is security-enabled, the function returns it; otherwise, it creates a new group
of type "security" using either a custom primary SMTP address (CustomDomain) or
a constructed address (DefaultDomain).

## EXAMPLES

### EXAMPLE 1
```
New-MailEnabledSendingGroup -Name "SecureSenders" -DefaultDomain "contoso.com"
```

Creates a new mail-enabled security group named "SecureSenders" with
a primary SMTP address of SecureSenders@contoso.com.

## PARAMETERS

### -Name
The name of the mail-enabled security group to create or retrieve.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Alias
An optional alias for the group.
If omitted, the group name is used as the alias.

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

### -PrimarySmtpAddress
(CustomDomain parameter set) The primary SMTP address to assign when using
a custom domain (e.g., MyGroup@contoso.com).

```yaml
Type: String
Parameter Sets: CustomDomain
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultDomain
(DefaultDomain parameter set) The domain to append to the alias, forming
an SMTP address (e.g., Alias@DefaultDomain).

```yaml
Type: String
Parameter Sets: DefaultDomain
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs. The cmdlet is not run.

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

### None. This function does not accept pipeline input.
## OUTPUTS

### Microsoft.Exchange.Data.Directory.Management.DistributionGroup
### Returns the newly created or existing mail-enabled security group object.
## NOTES
Requires connectivity to Exchange Online.
The caller must have sufficient
privileges to create or modify distribution groups.

## RELATED LINKS
