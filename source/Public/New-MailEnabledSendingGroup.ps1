<#
    .SYNOPSIS
        Creates or retrieves a mail-enabled security group with a custom or default domain.
    .DESCRIPTION
        The New-MailEnabledSendingGroup function ensures that a mail-enabled security
        group is available for restricting email sending. It connects to Exchange Online
        to verify if a group of the specified name already exists. If the existing group
        is security-enabled, the function returns it; otherwise, it creates a new group
        of type "security" using either a custom primary SMTP address (CustomDomain) or
        a constructed address (DefaultDomain).
    .PARAMETER Name
        The name of the mail-enabled security group to create or retrieve.
    .PARAMETER Alias
        An optional alias for the group. If omitted, the group name is used as the alias.
    .PARAMETER PrimarySmtpAddress
        (CustomDomain parameter set) The primary SMTP address to assign when using
        a custom domain (e.g., MyGroup@contoso.com).
    .PARAMETER DefaultDomain
        (DefaultDomain parameter set) The domain to append to the alias, forming
        an SMTP address (e.g., Alias@DefaultDomain).
    .EXAMPLE
        PS C:\> New-MailEnabledSendingGroup -Name "SecureSenders" -DefaultDomain "contoso.com"

        Creates a new mail-enabled security group named "SecureSenders" with
        a primary SMTP address of SecureSenders@contoso.com.
    .INPUTS
        None. This function does not accept pipeline input.
    .OUTPUTS
        Microsoft.Exchange.Data.Directory.Management.DistributionGroup
        Returns the newly created or existing mail-enabled security group object.
    .NOTES
        Requires connectivity to Exchange Online. The caller must have sufficient
        privileges to create or modify distribution groups.
#>

function New-MailEnabledSendingGroup {
    [CmdletBinding(DefaultParameterSetName = 'CustomDomain')]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Specifies the name of the mail enabled sending group.'
        )]
        [string]
        $Name,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional alias for the group. If not provided, the group name will be used.'
        )]
        [string]
        $Alias,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'CustomDomain',
            HelpMessage = 'Specifies the primary SMTP address for the group when using a custom domain.'
        )]
        [string]
        $PrimarySmtpAddress,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'DefaultDomain',
            HelpMessage = 'Specifies the default domain to construct the primary SMTP address (alias@DefaultDomain) for the group.'
        )]
        [string]
        $DefaultDomain
    )
    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    try {
        Connect-TkMsService -ExchangeOnline
        if (-not $Alias) {
            $Alias = $Name
        }
        if ($PSCmdlet.ParameterSetName -eq 'DefaultDomain') {
            $PrimarySmtpAddress = "$Alias@$DefaultDomain"
        }
        # Check if the distribution group already exists
        $existingGroup = Get-DistributionGroup -Identity $Name -ErrorAction SilentlyContinue
        if ($existingGroup) {
            # Confirm the group is security-enabled
            if ($existingGroup.GroupType -notmatch 'SecurityEnabled') {
                throw "Group '$Name' exists but is not SecurityEnabled. Please provide a mail-enabled security group."
            }
            Write-AuditLog -Message "Distribution group '$Name' already exists. Returning existing group."
            return $existingGroup
        }
        # Create the distribution group
        $groupParams = @{
            Name               = $Name
            Alias              = $Alias
            PrimarySmtpAddress = $PrimarySmtpAddress
            Type               = 'security'
        }
        Write-AuditLog -Message "Creating distribution group with parameters: `n$($groupParams | Out-String)"
        $group = New-DistributionGroup @groupParams
        Write-AuditLog -Message "Distribution group created:`n$($group | Out-String)"
        return $group
    }
    catch {
        throw
    }
    finally {
        Write-AuditLog -EndFunction
    }
}
