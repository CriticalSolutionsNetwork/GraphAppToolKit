<#
    .SYNOPSIS
        Installs or updates required PowerShell modules, with support for stable or pre-release versions.
    .DESCRIPTION
        The Initialize-TkModuleEnv function handles module installation and importing in a flexible manner.
        It checks for PowerShellGet (and updates it if needed), adjusts the function limit if the Microsoft.Graph
        module is included, and can install modules for either the CurrentUser or AllUsers scope. It supports
        both stable (Public) and pre-release modules, and optionally imports specific modules by name.
        Logging is handled via Write-AuditLog, and administrative privileges are required for certain operations
        (e.g., installing modules for AllUsers).
    .PARAMETER PublicModuleNames
        An array of stable module names to install when using the 'Public' parameter set.
    .PARAMETER PublicRequiredVersions
        An array of required stable module versions corresponding to each name in PublicModuleNames.
    .PARAMETER PrereleaseModuleNames
        An array of pre-release module names to install when using the 'Prerelease' parameter set.
    .PARAMETER PrereleaseRequiredVersions
        An array of required pre-release module versions corresponding to each name in PrereleaseModuleNames.
    .PARAMETER Scope
        Specifies whether to install the modules for the CurrentUser or AllUsers.
        Accepts 'CurrentUser' or 'AllUsers'. Requires administrative privileges for 'AllUsers'.
    .PARAMETER ImportModuleNames
        An optional list of modules to selectively import after installation. If not specified, all installed modules
        are imported.
    .EXAMPLE
        Initialize-TkModuleEnv -PublicModuleNames "PsNmap", "Microsoft.Graph" -PublicRequiredVersions "1.3.1","1.23.0" -Scope AllUsers
        Installs PsNmap and Microsoft.Graph in the AllUsers scope with the specified versions.
    .EXAMPLE
        $params1 = @{
            PublicModuleNames      = "PSnmap","Microsoft.Graph"
            PublicRequiredVersions = "1.3.1","1.23.0"
            ImportModuleNames      = "Microsoft.Graph.Authentication", "Microsoft.Graph.Identity.SignIns"
            Scope                  = "CurrentUser"
        }
        Initialize-TkModuleEnv @params1
        Installs and imports specific modules for Microsoft.Graph.
    .EXAMPLE
        $params2 = @{
            PrereleaseModuleNames      = "Sampler", "Pester"
            PrereleaseRequiredVersions = "2.1.5", "4.10.1"
            Scope                      = "CurrentUser"
        }
        Initialize-TkModuleEnv @params2
        Installs the pre-release versions of Sampler and Pester in the CurrentUser scope.
    .INPUTS
        None. You cannot pipe input into this function.
    .OUTPUTS
        None. This function does not return objects to the pipeline.
    .NOTES
        Author: DrIOSx
        Requires: Write-AuditLog, Test-IsAdmin
        - This function checks for and updates PowerShellGet if needed.
        - It sets the function limit to 8192 if the Microsoft.Graph module is included and PowerShell is 5.1.
        - If the user lacks administrative privileges but tries to install to AllUsers, it throws an error.
#>
function Initialize-TkModuleEnv {
    [CmdletBinding(DefaultParameterSetName = 'Public')]
    param(
        [Parameter(
            ParameterSetName = 'Public',
            Mandatory
        )]
        [string[]]
        $PublicModuleNames,
        [Parameter(
            ParameterSetName = 'Public',
            Mandatory
        )]
        [string[]]
        $PublicRequiredVersions,
        [Parameter(
            ParameterSetName = 'Prerelease',
            Mandatory
        )]
        [string[]]
        $PrereleaseModuleNames,
        [Parameter(
            ParameterSetName = 'Prerelease',
            Mandatory
        )]
        [string[]]
        $PrereleaseRequiredVersions,
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string]
        $Scope,
        [string[]]
        $ImportModuleNames = $null
    )
    if (-not $script:LogString) { Write-AuditLog -Start }else { Write-AuditLog -BeginFunction }
    Write-AuditLog '###########################################################'
    try {
        # If Microsoft.Graph is being installed, raise function limit if < 8192.
        if (($PublicModuleNames -match 'Microsoft.Graph') -or ($PrereleaseModuleNames -match 'Microsoft.Graph')) {
            if ($script:MaximumFunctionCount -lt 8192) {
                $script:MaximumFunctionCount = 8192
            }
        }
        # Step 1: Check/Update PowerShellGet if needed
        $psGetModules = Get-Module -Name PowerShellGet -ListAvailable
        $hasNonDefaultVer = $false
        foreach ($mod in $psGetModules) {
            if ($mod.Version -ne '1.0.0.1') {
                $hasNonDefaultVer = $true
                break
            }
        }
        if ($hasNonDefaultVer) {
            # Import the latest version
            $latestModule = $psGetModules | Sort-Object Version -Descending | Select-Object -First 1
            Import-Module -Name $latestModule.Name -RequiredVersion $latestModule.Version -ErrorAction Stop
        }
        else {
            if (-not(Test-IsAdmin)) {
                Write-AuditLog 'PowerShellGet is version 1.0.0.1. Please run once as admin to update PowerShellGet.' -Severity Error
                throw 'Elevation required to update PowerShellGet!'
            }
            else {
                Write-AuditLog 'Updating PowerShellGet...'
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
                Install-Module PowerShellGet -AllowClobber -Force -ErrorAction Stop
                $psGetModules = Get-Module -Name PowerShellGet -ListAvailable
                $latestModule = $psGetModules | Sort-Object Version -Descending | Select-Object -First 1
                Import-Module -Name $latestModule.Name -RequiredVersion $latestModule.Version -ErrorAction Stop
            }
        }
        # Step 2: Validate scope
        if ($Scope -eq 'AllUsers') {
            if (-not(Test-IsAdmin)) {
                Write-AuditLog "You must be an administrator to install in 'AllUsers' scope." -Severity Error
                throw "Elevation required for 'AllUsers' scope."
            }
            else {
                Write-AuditLog "Installing modules for 'AllUsers' scope."
            }
        }
        # Step 3: Determine module set
        $prerelease = $false
        if ($PSCmdlet.ParameterSetName -eq 'Public') {
            $modules = $PublicModuleNames
            $versions = $PublicRequiredVersions
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Prerelease') {
            $modules = $PrereleaseModuleNames
            $versions = $PrereleaseRequiredVersions
            $prerelease = $true
        }
        # Step 4: Install/Import each module
        foreach ($m in $modules) {
            $requiredVersion = $versions[$modules.IndexOf($m)]
            $installed = Get-Module -Name $m -ListAvailable | Where-Object { [version]$_.Version -ge [version]$requiredVersion } | Sort-Object Version -Descending | Select-Object -First 1
            $SelectiveImports = $null
            if ($ImportModuleNames) {
                $SelectiveImports = $ImportModuleNames | Where-Object { $_ -match $m }
            }
            if (-not $installed) {
                $msgPrefix = if ($prerelease) { 'PreRelease' }else { 'stable' }
                Write-AuditLog "The $msgPrefix module $m version $requiredVersion (or higher) is not installed." -Severity Warning
                Write-AuditLog "Installing $m version $requiredVersion -AllowPrerelease:$prerelease."
                Install-Module $m -Scope $Scope -RequiredVersion $requiredVersion -AllowPrerelease:$prerelease -ErrorAction Stop
                Write-AuditLog "$m module successfully installed!"
                if ($SelectiveImports) {
                    foreach ($ModName in $SelectiveImports) {
                        Write-AuditLog "Importing $ModName."
                        Import-Module $ModName -ErrorAction Stop
                        Write-AuditLog "Successfully imported $ModName."
                    }
                }
                else {
                    Write-AuditLog "Importing $m"
                    Import-Module $m -ErrorAction Stop
                    Write-AuditLog "Successfully imported $m"
                }
            }
            else {
                Write-AuditLog "$m v$($installed.Version) exists."
                if ($SelectiveImports) {
                    foreach ($ModName in $SelectiveImports) {
                        Write-AuditLog "Importing SubModule: $ModName."
                        Import-Module $ModName -ErrorAction Stop
                        Write-AuditLog "Imported SubModule: $ModName."
                    }
                }
                else {
                    Write-AuditLog "Importing $m"
                    Import-Module $m -ErrorAction Stop
                    Write-AuditLog "Imported $m"
                }
            }
        }
    }
    catch {
        throw
    }
    finally {
        Write-AuditLog -EndFunction
    }
}
