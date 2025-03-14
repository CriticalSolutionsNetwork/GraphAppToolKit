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
The New-MailEnabledSendingGroup function ensures that a mail-enabled security group is
available for restricting email sending in Exchange Online.
If a group of the specified
name already exists and is security-enabled, the function returns that group.
Otherwise,
it creates a new security-enabled distribution group.
You can specify either a custom
primary SMTP address (via the 'CustomDomain' parameter set) or construct one using an
alias and default domain (via the 'DefaultDomain' parameter set).
By default, the 'CustomDomain' parameter set is used.
If you wish to construct the SMTP
address from the alias, switch to the 'DefaultDomain' parameter set.

## EXAMPLES

### EXAMPLE 1
```
New-MailEnabledSendingGroup -Name "SecureSenders" -DefaultDomain "contoso.com"
Creates a new mail-enabled security group named "SecureSenders" with a primary SMTP address
of SecureSenders@contoso.com.
```

### EXAMPLE 2
```
New-MailEnabledSendingGroup -Name "SecureSenders" -Alias "Senders" -PrimarySmtpAddress "Senders@customdomain.org"
Creates a new mail-enabled security group named "SecureSenders" with an alias "Senders"
and a primary SMTP address of Senders@customdomain.org.
```

## PARAMETERS

### -Name
The name of the mail-enabled security group to create or retrieve.
This is also used as
the alias if no separate Alias parameter is provided.

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
(CustomDomain parameter set) The full SMTP address for the group (e.g.
"MyGroup@contoso.com").
This parameter is mandatory when using the 'CustomDomain' parameter set.

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
(DefaultDomain parameter set) The domain portion to be appended to the group alias (e.g.
"Alias@DefaultDomain").
This parameter is mandatory when using the 'DefaultDomain' parameter set.

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

### None. This function does not accept pipeline input.
## OUTPUTS

### Microsoft.Exchange.Data.Directory.Management.DistributionGroup
### Returns the newly created or existing mail-enabled security group object.
## NOTES
- Requires connectivity to Exchange Online (Connect-TkMsService -ExchangeOnline).
- The caller must have sufficient privileges to create or modify distribution groups.
- DefaultParameterSetName = 'CustomDomain'.

## RELATED LINKS
