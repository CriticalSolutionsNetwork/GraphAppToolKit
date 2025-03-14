<#
    .SYNOPSIS
    Creates a new Exchange email application policy and optionally adds a user to a mail-enabled sending group.
    .DESCRIPTION
    The New-TkExchangeEmailAppPolicy function creates a new Exchange application access policy for a specified application registration and mail-enabled sending group. Optionally, it can add an authorized sender to the mail-enabled sending group.
    .PARAMETER AppRegistration
    The application registration object. This parameter is mandatory.
    .PARAMETER MailEnabledSendingGroup
    The mail-enabled sending group. This parameter is mandatory.
    .PARAMETER AuthorizedSenderUserName
    The username of the authorized sender to be added to the mail-enabled sending group. This parameter is optional.
    .EXAMPLE
    $AppRegistration = Get-MgApplication -ApplicationId "your-app-id"
    New-TkExchangeEmailAppPolicy -AppRegistration $AppRegistration -MailEnabledSendingGroup "YourGroup" -AuthorizedSenderUserName "UserName"
    This example creates a new Exchange application access policy for the specified application registration and mail-enabled sending group, and adds the specified user to the mail-enabled sending group.
    .EXAMPLE
    $AppRegistration = Get-MgApplication -ApplicationId "your-app-id"
    New-TkExchangeEmailAppPolicy -AppRegistration $AppRegistration -MailEnabledSendingGroup "YourGroup"

    This example creates a new Exchange application access policy for the specified application registration and mail-enabled sending group without adding any user to the group.
    .NOTES
    This function uses the Microsoft Graph PowerShell module and requires appropriate permissions to manage Exchange policies and distribution groups.
#>
function New-TkExchangeEmailAppPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The application registration object.'
        )]
        [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphApplication]
        $AppRegistration,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The Mail Enabled Sending Group.'
        )]
        [string]
        $MailEnabledSendingGroup,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Authorized Sender UserName'
        )]
        [string]
        $AuthorizedSenderUserName
    )
    # Begin Logging
    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    try {
        $shouldProcessTarget = "'$MailEnabledSendingGroup, $AuthorizedSenderUserName' on AppId '$($AppRegistration.AppId)'"
        $shouldProcessOperation = 'Add-DistributionGroupMember, New-ApplicationAccessPolicy'
        if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
            if ($PSBoundParameters.ContainsKey('AuthorizedSenderUserName')) {
                Write-AuditLog "Adding User: $AuthorizedSenderUserName to the Mail Enabled Sending Group: $MailEnabledSendingGroup"
                Add-DistributionGroupMember `
                    -Identity $MailEnabledSendingGroup `
                    -Member $AuthorizedSenderUserName `
                    -Confirm:$false `
                    -ErrorAction Stop
            }
            Write-AuditLog -Message "Creating Exchange Application policy for $($MailEnabledSendingGroup) for AppId $($AppRegistration.AppId)."
            New-ApplicationAccessPolicy -AppId $AppRegistration.AppId `
                -PolicyScopeGroupId $MailEnabledSendingGroup -AccessRight RestrictAccess `
                -Description 'Limit MSG application to only send emails as a group of users' `
                -Confirm:$false `
                -ErrorAction Stop | Out-Null
            Write-AuditLog -Message "Created Exchange Application policy for $($MailEnabledSendingGroup)."
        }
    }
    catch {
        Write-AuditLog -Message "Error creating Exchange Application policy: $_"
        throw
    }
    Write-AuditLog -EndFunction
}
