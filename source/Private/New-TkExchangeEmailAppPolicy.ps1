function New-TkExchangeEmailAppPolicy {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The application registration object.'
        )]
        [PSObject]
        $AppRegistration,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The Mail Enabled Sending Group.'
        )]
        [string]
        $MailEnabledSendingGroup
    )
    # Begin Logging
    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    try {
        Write-AuditLog -Message "Creating Exchange Application policy for $($MailEnabledSendingGroup) for AppId $($AppRegistration.AppId)."
        New-ApplicationAccessPolicy -AppId $AppRegistration.AppId `
            -PolicyScopeGroupId $MailEnabledSendingGroup -AccessRight RestrictAccess `
            -Description 'Limit MSG application to only send emails as a group of users' -ErrorAction Stop
        Write-AuditLog -Message "Created Exchange Application policy for $($MailEnabledSendingGroup)."
    }
    catch {
        throw
    }
    Write-AuditLog -EndFunction
}
