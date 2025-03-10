---
external help file: GraphAppToolkit-help.xml
Module Name: GraphAppToolkit
online version:
schema: 2.0.0
---

# Send-TkEmailAppMessage

## SYNOPSIS
Sends an email using the Microsoft Graph API, either by retrieving app credentials from a local vault
or by specifying them manually.

## SYNTAX

### Vault (Default)
```
Send-TkEmailAppMessage -AppName <String> -To <String> -FromAddress <String> -Subject <String>
 -EmailBody <String> [-AttachmentPath <String[]>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Manual
```
Send-TkEmailAppMessage -AppId <String> -TenantId <String> -CertThumbprint <String> -To <String>
 -FromAddress <String> -Subject <String> -EmailBody <String> [-AttachmentPath <String[]>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Send-TkEmailAppMessage function uses the Microsoft Graph API to send an email to a specified
recipient.
It supports two parameter sets:

1.
'Vault' (default): Provide an existing app name (AppName) whose credentials are stored in the local
    secret vault (e.g., GraphEmailAppLocalStore).
The function retrieves the AppId, TenantId, and
    certificate thumbprint automatically.
2.
'Manual': Provide the AppId, TenantId, and certificate thumbprint yourself, bypassing the vault.
In both cases, the function obtains an OAuth2 token (via MSAL.PS) using the specified certificate
and uses the Microsoft Graph 'sendMail' endpoint to deliver the message.

## EXAMPLES

### EXAMPLE 1
```
# Using the 'Vault' parameter set
Send-TkEmailAppMessage -AppName "GraphEmailApp" -To "recipient@example.com" -FromAddress "sender@example.com" `
                    -Subject "Test Email" -EmailBody "This is a test email."
```

In this example, the function retrieves the app's credentials (AppId, TenantId, CertThumbprint) from the
local vault (GraphEmailAppLocalStore) under the secret name "GraphEmailApp."

### EXAMPLE 2
```
# Using the 'Manual' parameter set
Send-TkEmailAppMessage -AppId "00000000-1111-2222-3333-444444444444" -TenantId "contoso.onmicrosoft.com" `
                    -CertThumbprint "AABBCCDDEEFF11223344556677889900" -To "recipient@example.com" `
                    -FromAddress "sender@example.com" -Subject "Manual Email" -EmailBody "Hello from Manual!"
```

In this example, no vault entry is used.
Instead, the function directly uses the provided AppId,
TenantId, and CertThumbprint to obtain a token and send an email.

## PARAMETERS

### -AppName
\[Vault Parameter Set Only\]
The name of the pre-created Microsoft Graph Email App (stored in GraphEmailAppLocalStore).
This parameter is used only if the 'Vault' parameter set is chosen.
The function retrieves
the AppId, TenantId, and certificate thumbprint from the vault entry.

```yaml
Type: String
Parameter Sets: Vault
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AppId
\[Manual Parameter Set Only\]
The Azure AD application (client) ID to use for sending the email.
Must be used together with
TenantId and CertThumbprint in the 'Manual' parameter set.

```yaml
Type: String
Parameter Sets: Manual
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TenantId
\[Manual Parameter Set Only\]
The Azure AD tenant ID (GUID or domain name).
Must be used together with AppId and CertThumbprint
in the 'Manual' parameter set.

```yaml
Type: String
Parameter Sets: Manual
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertThumbprint
\[Manual Parameter Set Only\]
The certificate thumbprint (in Cert:\CurrentUser\My) used for authenticating as the Azure AD app.
Must be used together with AppId and TenantId in the 'Manual' parameter set.

```yaml
Type: String
Parameter Sets: Manual
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -To
The email address of the recipient.

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

### -FromAddress
The email address of the sender who is authorized to send email as configured in the Graph Email App.

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

### -Subject
The subject line of the email.

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

### -EmailBody
The body text of the email.

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

### -AttachmentPath
An array of file paths for any attachments to include in the email.
Each path must exist as a leaf file.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

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

## OUTPUTS

## NOTES
- This function requires the Microsoft.Graph, SecretManagement, SecretManagement.JustinGrote.CredMan,
    and MSAL.PS modules to be installed and imported (handled automatically via Initialize-TkModuleEnv).
- For the 'Vault' parameter set, the local vault secret must store JSON properties including AppId,
    TenantID, and CertThumbprint.
- Refer to https://learn.microsoft.com/en-us/graph/outlook-send-mail for more details on sending mail
    via Microsoft Graph.

## RELATED LINKS
