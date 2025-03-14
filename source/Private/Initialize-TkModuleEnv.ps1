<#
    .SYNOPSIS
    Initializes the environment by installing and importing specified PowerShell modules.
    .DESCRIPTION
    The Initialize-TkModuleEnv function installs and imports specified PowerShell modules, either public or pre-release versions, based on the provided parameters. It also ensures that the PowerShellGet module is up-to-date and handles the installation scope, requiring elevation for 'AllUsers' scope. The function logs the installation and import process using Write-AuditLog.
    .PARAMETER PublicModuleNames
    An array of public module names to be installed.
    .PARAMETER PublicRequiredVersions
    An array of required versions corresponding to the public module names.
    .PARAMETER PrereleaseModuleNames
    An array of pre-release module names to be installed.
    .PARAMETER PrereleaseRequiredVersions
    An array of required versions corresponding to the pre-release module names.
    .PARAMETER Scope
    The installation scope, either 'AllUsers' or 'CurrentUser'.
    .PARAMETER ImportModuleNames
    An optional array of module names to be imported after installation.
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
    .NOTES
    - If Microsoft.Graph is being installed, the function limit is raised to 8192 if it is less than that.
    - The function checks and updates PowerShellGet if needed.
    - The function validates the installation scope and requires elevation for 'AllUsers' scope.
    - The function logs the installation and import process using Write-AuditLog.
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
    if (-not $script:LogString) {
        Write-AuditLog -Start
    } else {
        Write-AuditLog -BeginFunction
    }
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
