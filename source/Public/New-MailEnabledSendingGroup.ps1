<#
    .SYNOPSIS
        Creates or retrieves a mail-enabled security group with a custom or default domain.
    .DESCRIPTION
        The New-MailEnabledSendingGroup function ensures that a mail-enabled security group is
        available for restricting email sending in Exchange Online. If a group of the specified
        name already exists and is security-enabled, the function returns that group. Otherwise,
        it creates a new security-enabled distribution group. You can specify either a custom
        primary SMTP address (via the 'CustomDomain' parameter set) or construct one using an
        alias and default domain (via the 'DefaultDomain' parameter set).
        By default, the 'CustomDomain' parameter set is used. If you wish to construct the SMTP
        address from the alias, switch to the 'DefaultDomain' parameter set.
    .PARAMETER Name
        The name of the mail-enabled security group to create or retrieve. This is also used as
        the alias if no separate Alias parameter is provided.
    .PARAMETER Alias
        An optional alias for the group. If omitted, the group name is used as the alias.
    .PARAMETER PrimarySmtpAddress
        (CustomDomain parameter set) The full SMTP address for the group (e.g. "MyGroup@contoso.com").
        This parameter is mandatory when using the 'CustomDomain' parameter set.
    .PARAMETER DefaultDomain
        (DefaultDomain parameter set) The domain portion to be appended to the group alias (e.g.
        "Alias@DefaultDomain"). This parameter is mandatory when using the 'DefaultDomain' parameter set.
    .EXAMPLE
        PS C:\> New-MailEnabledSendingGroup -Name "SecureSenders" -DefaultDomain "contoso.com"
        Creates a new mail-enabled security group named "SecureSenders" with a primary SMTP address
        of SecureSenders@contoso.com.
    .EXAMPLE
        PS C:\> New-MailEnabledSendingGroup -Name "SecureSenders" -Alias "Senders" -PrimarySmtpAddress "Senders@customdomain.org"
        Creates a new mail-enabled security group named "SecureSenders" with an alias "Senders"
        and a primary SMTP address of Senders@customdomain.org.
    .INPUTS
        None. This function does not accept pipeline input.
    .OUTPUTS
        Microsoft.Exchange.Data.Directory.Management.DistributionGroup
        Returns the newly created or existing mail-enabled security group object.
    .NOTES
        - Requires connectivity to Exchange Online (Connect-TkMsService -ExchangeOnline).
        - The caller must have sufficient privileges to create or modify distribution groups.
        - DefaultParameterSetName = 'CustomDomain'.
#>
function New-MailEnabledSendingGroup {
    [CmdletBinding(SupportsShouldProcess = $true , DefaultParameterSetName = 'CustomDomain')]
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
        # TODO Add confirmation prompt
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
        $shouldProcessOperation = 'New-DistributionGroup'
        $shouldProcessTarget = "'$PrimarySmtpAddress'"
        if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
            $group = New-DistributionGroup @groupParams
            Write-AuditLog -Message "Distribution group created:`n$($group | Out-String)"
            return $group
        }
    }
    catch {
        throw
    }
    finally {
        Write-AuditLog -EndFunction
    }
}
