<#
    .SYNOPSIS
    Generates a new application name based on provided prefix, scenario name, and user email.
    .DESCRIPTION
    The Initialize-TkAppName function constructs an application name using a specified prefix, an optional scenario name,
    and an optional user email. The generated name includes a domain suffix derived from the environment variable USERDNSDOMAIN.
    .PARAMETER Prefix
    A short prefix for your app name (2-4 alphanumeric characters). This parameter is mandatory.
    .PARAMETER ScenarioName
    An optional scenario name to include in the app name (e.g., AuditGraphEmail, MemPolicy, etc.). Defaults to "GraphApp".
    .PARAMETER UserId
    An optional user email to append an "As-[username]" suffix to the app name. The email must be in a valid format.
    .EXAMPLE
    PS> Initialize-TkAppName -Prefix "MSN"
    Generates an app name with the prefix "MSN" and default scenario name "GraphApp".
    .EXAMPLE
    PS> Initialize-TkAppName -Prefix "MSN" -ScenarioName "AuditGraphEmail"
    Generates an app name with the prefix "MSN" and scenario name "AuditGraphEmail".
    .EXAMPLE
    PS> Initialize-TkAppName -Prefix "MSN" -UserId "helpdesk@mydomain.com"
    Generates an app name with the prefix "MSN" and appends the user suffix derived from the email "helpdesk@mydomain.com".
    .NOTES
    The function logs the process of building the app name and handles errors by logging and throwing them.
#>
function Initialize-TkAppName {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(
            Mandatory=$true,
            HelpMessage='A short prefix for your app name (2-4 alphanumeric chars).'
        )]
        [ValidatePattern('^[A-Z0-9]{2,4}$')]
        [string]
        $Prefix,
        [Parameter(
            Mandatory=$false,
            HelpMessage='Optional scenario name (e.g. AuditGraphEmail, MemPolicy, etc.).'
        )]
        [string]
        $ScenarioName = "GraphApp",
        [Parameter(
            Mandatory=$false,
            HelpMessage='Optional user email to append "As-[username]" suffix.'
        )]
        [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$')]
        [string]
        $UserId
    )
    begin {
        if (-not $script:LogString) { Write-AuditLog -Start } else { Write-AuditLog -BeginFunction }
    }
    process {
        try {
            Write-AuditLog "Building app name..."
            # Build a user suffix if $UserId is provided
            $userSuffix = ""
            if ($UserId) {
                # e.g. "helpdesk@mydomain.com" -> "As-helpDesk"
                $userPrefix = ($UserId.Split('@')[0])
                $userSuffix = "-As-$userPrefix"
            }
            # Example final: GraphToolKit-MSN-GraphApp-MyDomain-As-helpDesk
            $domainSuffix = $env:USERDNSDOMAIN
            if (-not $domainSuffix) {
                # fallback if not set
                $domainSuffix = "MyDomain"
            }
            $appName = "GraphToolKit-$Prefix"
            Write-AuditLog "Returning app name: $appName (Prefix: $Prefix, Scenario: $ScenarioName, User Suffix: $userSuffix)"
            $appName += "-$domainSuffix"
            $appName += "$userSuffix"
            Write-AuditLog "Returning app name: $appName"
            return $appName
        }
        catch {
            $errorMessage = "An error occurred while building the app name: $_"
            Write-AuditLog $errorMessage
            throw $errorMessage
        }
        finally {
            Write-AuditLog -EndFunction
        }
    }
}
