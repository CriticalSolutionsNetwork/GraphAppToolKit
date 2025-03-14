<#
    .SYNOPSIS
    Connects to Microsoft Graph and/or Exchange Online services.
    .DESCRIPTION
    The Connect-TkMsService function establishes a connection to Microsoft Graph and/or Exchange Online services.
    It checks for existing sessions and reuses them if valid, otherwise, it creates new sessions.
    The function supports logging and provides detailed information about the connection process.
    .PARAMETER MgGraph
    Switch parameter to indicate if a connection to Microsoft Graph should be established.
    .PARAMETER GraphAuthScopes
    Array of strings specifying the scopes required for Microsoft Graph authentication.
    .PARAMETER ExchangeOnline
    Switch parameter to indicate if a connection to Exchange Online should be established.
    .EXAMPLE
    Connect-TkMsService -MgGraph -GraphAuthScopes @('User.Read', 'Mail.Read')

    This example connects to Microsoft Graph with the specified scopes.
    .EXAMPLE
    Connect-TkMsService -ExchangeOnline

    This example connects to Exchange Online.
    .EXAMPLE
    Connect-TkMsService -MgGraph -GraphAuthScopes @('User.Read', 'Mail.Read') -ExchangeOnline

    This example connects to both Microsoft Graph and Exchange Online.
    .NOTES
    This function requires the Microsoft.Graph and ExchangeOnlineManagement modules to be installed and imported.
#>
function Connect-TkMsService {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(
            HelpMessage = 'Connect to Microsoft Graph.'
        )]
        [Switch]
        $MgGraph,
        [Parameter(
            HelpMessage = 'Graph Scopes.'
        )]
        [String[]]
        $GraphAuthScopes,
        [Parameter(
            HelpMessage = 'Connect to Exchange Online.'
        )]
        [Switch]
        $ExchangeOnline
    )
    # Begin Logging
    if (-not $script:LogString) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    Write-AuditLog '###############################################'
    #----------------------------------------------
    # Section 1: Microsoft Graph
    #----------------------------------------------
    if ($MgGraph) {
        $shouldProcessTarget = $GraphAuthScopes -join ', '
        $shouldProcessOperation = 'Connect-MgGraph'
        if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
            try {
                # 1) Attempt to see if we have a valid Graph session
                $graphIsValid = $false
                try {
                    # If this succeeds, presumably we have a valid token/context
                    Get-MgUser -Top 1 -ErrorAction Stop | Out-Null
                    $ContextMg = Get-MgContext -ErrorAction Stop
                    # Check required scopes
                    <#
                        $scopesNeeded = @(
                            'Application.ReadWrite.All',
                            'DelegatedPermissionGrant.ReadWrite.All',
                            'Directory.ReadWrite.All',
                            'RoleManagement.ReadWrite.Directory'
                        )
                    #>
                    $scopesNeeded = $GraphAuthScopes
                    $missing = $scopesNeeded | Where-Object { $ContextMg.Scopes -notcontains $_ }
                    if ($missing) {
                        Write-AuditLog "The following needed scopes are missing: $($missing -join ', ')"
                    }
                    else {
                        Write-AuditLog 'An active Microsoft Graph session is detected and all required scopes are present.'
                        $graphIsValid = $true
                    }
                }
                catch {
                    # Either no session or it's invalid/expired
                    $graphIsValid = $false
                }
                # 2) If valid session, ask user if they want to reuse it
                if ($graphIsValid) {
                    $org = Get-MgOrganization -ErrorAction Stop
                    $shouldProcessTarget = 'Microsoft Graph'
                    $shouldProcessOperation = "Use existing session for Account: $($context.Account) Tenant: $($org.DisplayName) AuthType: $($context.AuthType)"
                    if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
                        Write-AuditLog 'Using existing Microsoft Graph session.'
                    }
                    else {
                        # Remove the old context so we can connect fresh
                        Remove-MgContext -ErrorAction SilentlyContinue
                        Write-AuditLog 'Creating a new Microsoft Graph session.'
                        Connect-MgGraph -Scopes $scopesNeeded `
                            -ErrorAction Stop
                        Write-AuditLog 'Connected to Microsoft Graph.'
                    }
                }
                else {
                    # No valid session, so just connect
                    Write-AuditLog 'No valid Microsoft Graph session found. Connecting...'
                    Connect-MgGraph -Scopes $scopesNeeded `
                        -ErrorAction Stop
                    Write-AuditLog 'Connected to Microsoft Graph.'
                }
            }
            catch {
                Write-AuditLog -Severity Error -Message "Error connecting to Microsoft Graph. Error: $($_.Exception.Message)"
                throw
            }
        }
    }
    #----------------------------------------------
    # Section 2: Exchange Online
    #----------------------------------------------
    if ($ExchangeOnline) {
        $shouldProcessTarget = 'Connecting to Exchange Online using modern authentication pop-up.'
        $shouldProcessOperation = 'Connect-ExchangeOnline'
        if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
            try {
                # 1) Attempt to see if we have a valid Exchange session
                $exoIsValid = $false
                try {
                    $ExoOrg = Get-OrganizationConfig -ErrorAction Stop
                    $exoIsValid = $true
                }
                catch {
                    # Either no session or it's invalid/expired
                    $exoIsValid = $false
                }
                # 2) If valid session, ask user if they want to reuse it
                if ($exoIsValid) {
                    Write-AuditLog 'An active Exchange Online session is detected.'
                    Write-AuditLog "Tenant: `n$($ExoOrg.DisplayName)`n"
                    $shouldProcessTarget = 'ExchangeOnline'
                    $shouldProcessOperation = "Use existing session for Org: $($ExoOrg.DisplayName) OnMicrosoftId: $($ExoOrg.Name )"
                    if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
                        Write-AuditLog 'Using existing Exchange Online session.'
                    }
                    else {
                        # Disconnect old session
                        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
                        Write-AuditLog 'Creating new Exchange Online session.'
                        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
                        Write-AuditLog 'Connected to Exchange Online.'
                    }
                }
                else {
                    Write-AuditLog 'No valid Exchange Online session found. Connecting...'
                    Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
                    Write-AuditLog 'Connected to Exchange Online.'
                }
            }
            catch {
                Write-AuditLog -Severity Error -Message "Error connecting to Exchange Online. Error: $($_.Exception.Message)"
                throw
            }
        }
    }
    Write-AuditLog -EndFunction
}
