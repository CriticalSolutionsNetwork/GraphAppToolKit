<#
    .SYNOPSIS
    Initializes the environment by installing and importing specified PowerShell modules.
    .DESCRIPTION
    The Initialize-TkModuleEnv function installs and imports specified PowerShell modules, either public or pre-release versions, based on the provided parameters. It also ensures that the PowerShellGet module is up-to-date and handles the installation scope, requiring elevation for 'AllUsers' scope. The function logs the installation and import process using Write-AuditLog.
    .PARAMETER PublicModuleNames
    An array of public module names to be installed and imported from the PowerShell Gallery. Each module must exist in the gallery.
    .PARAMETER PublicMinimumVersions
    An array of minimum versions corresponding to the public module names. Must match the count of PublicModuleNames.
    .PARAMETER PrereleaseModuleNames
    An array of pre-release module names to be installed from the PowerShell Gallery. Used for modules in preview/beta state.
    .PARAMETER PrereleaseMinimumVersions
    An array of minimum versions corresponding to the pre-release module names. Must match the count of PrereleaseModuleNames.
    .PARAMETER Scope
    The installation scope, either 'AllUsers' (requires elevation) or 'CurrentUser' (default, no elevation needed).
    .PARAMETER ImportModuleNames
    An optional array of module names to be imported after installation. Useful for importing specific modules from a larger package.
    .INPUTS
    None. This function does not accept pipeline input.
    .OUTPUTS
    None. This function does not generate output.
    .EXAMPLE
    $params1 = @{
        PublicModuleNames      = "PSnmap","Microsoft.Graph"
        PublicMinimumVersions = "1.3.1","1.23.0"
        ImportModuleNames      = "Microsoft.Graph.Authentication", "Microsoft.Graph.Identity.SignIns"
        Scope                  = "CurrentUser"
    }
    Initialize-TkModuleEnv @params1
    Installs and imports specific modules for Microsoft.Graph.
    .EXAMPLE
    $params2 = @{
        PrereleaseModuleNames      = "Sampler", "Pester"
        PrereleaseMinimumVersions = "2.1.5", "4.10.1"
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
            Mandatory,
            HelpMessage = 'Array of public module names to be installed from the PowerShell Gallery'
        )]
        [string[]]
        $PublicModuleNames,

        [Parameter(
            ParameterSetName = 'Public',
            Mandatory,
            HelpMessage = 'Array of minimum versions corresponding to the public module names'
        )]
        [string[]]
        $PublicMinimumVersions,

        [Parameter(
            ParameterSetName = 'Prerelease',
            Mandatory,
            HelpMessage = 'Array of pre-release module names to be installed from the PowerShell Gallery'
        )]
        [string[]]
        $PrereleaseModuleNames,

        [Parameter(
            ParameterSetName = 'Prerelease',
            Mandatory,
            HelpMessage = 'Array of minimum versions corresponding to the pre-release module names'
        )]
        [string[]]
        $PrereleaseMinimumVersions,

        [Parameter(
            HelpMessage = 'Installation scope, either AllUsers (requires admin) or CurrentUser'
        )]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string]
        $Scope,

        [Parameter(
            HelpMessage = 'Optional array of module names to import after installation (useful for submodules)'
        )]
        [string[]]
        $ImportModuleNames = $null
    )

    if (-not $script:LogString) { Write-AuditLog -Start } else { Write-AuditLog -BeginFunction }
    Write-AuditLog '###########################################################'

    try {
        # If Microsoft.Graph is being installed, raise function limit if < 8192.
        if (($PublicModuleNames -match 'Microsoft.Graph') -or ($PrereleaseModuleNames -match 'Microsoft.Graph')) {
            if ($script:MaximumFunctionCount -lt 8192) {
                $script:MaximumFunctionCount = 8192
                Write-AuditLog "Increased maximum function count to $script:MaximumFunctionCount for Microsoft.Graph" -Severity Information
            }
        }

        # Step 1: Check/Update PowerShellGet if needed
        $psGetModules = Get-Module -Name PowerShellGet -ListAvailable
        $hasNonDefaultVer = $false
        foreach ($mod in $psGetModules) {
            if ($mod.Version -ne '1.0.0.1') { $hasNonDefaultVer = $true; break }
        }

        if ($hasNonDefaultVer) {
            # Import the latest version
            $latestModule = $psGetModules | Sort-Object Version -Descending | Select-Object -First 1
            Import-Module -Name $latestModule.Name -RequiredVersion $latestModule.Version -ErrorAction Stop
            Write-AuditLog "Imported PowerShellGet version $($latestModule.Version)" -Severity Information
        }
        else {
            if (-not (Test-IsAdmin)) {
                Write-AuditLog 'PowerShellGet is version 1.0.0.1. Please run once as admin to update PowerShellGet.' -Severity Error
                throw 'Elevation required to update PowerShellGet!'
            }
            else {
                Write-AuditLog 'Updating PowerShellGet...' -Severity Information
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
                Install-Module PowerShellGet -AllowClobber -Force -ErrorAction Stop
                $psGetModules = Get-Module -Name PowerShellGet -ListAvailable
                $latestModule = $psGetModules | Sort-Object Version -Descending | Select-Object -First 1
                Import-Module -Name $latestModule.Name -RequiredVersion $latestModule.Version -ErrorAction Stop
                Write-AuditLog "Updated and imported PowerShellGet version $($latestModule.Version)" -Severity Information
            }
        }

        # Step 2: Validate scope
        if ($Scope -eq 'AllUsers') {
            if (-not (Test-IsAdmin)) {
                Write-AuditLog "You must be an administrator to install in 'AllUsers' scope." -Severity Error
                throw "Elevation required for 'AllUsers' scope."
            } else {
                Write-AuditLog "Installing modules for 'AllUsers' scope." -Severity Information
            }
        }

        # Step 3: Determine module set
        $prerelease = $false
        if ($PSCmdlet.ParameterSetName -eq 'Public') {
            $modules  = $PublicModuleNames
            $versions = $PublicMinimumVersions
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Prerelease') {
            $modules  = $PrereleaseModuleNames
            $versions = $PrereleaseMinimumVersions
            $prerelease = $true
        }

        # Step 4: Install/Import each module
        for ($i = 0; $i -lt $modules.Count; $i++) {
            $m = $modules[$i]
            $minVersion = $versions[$i]  # new name
            $installed = Get-Module -Name $m -ListAvailable |
                Where-Object { [version]$_.Version -ge [version]$minVersion } |
                Sort-Object Version -Descending |
                Select-Object -First 1

            $SelectiveImports = $null
            if ($ImportModuleNames) {
                $SelectiveImports = $ImportModuleNames | Where-Object { $_ -match $m }
            }

            if (-not $installed) {
                $msgPrefix = if ($prerelease) { 'PreRelease' } else { 'stable' }
                Write-AuditLog "The $msgPrefix module $m minimum version $minVersion is not installed." -Severity Warning
                Write-AuditLog "Installing $m (minimum $minVersion) -AllowPrerelease:$prerelease."

                try {
                    Install-Module $m -Scope $Scope -MinimumVersion $minVersion -AllowPrerelease:$prerelease -ErrorAction Stop
                    Write-AuditLog "$m module successfully installed!" -Severity Information
                }
                catch {
                    Write-AuditLog "Failed to install $m (min $minVersion): $(${($_.Exception.Message)})" -Severity Error
                    throw
                }

                if ($SelectiveImports) {
                    foreach ($ModName in $SelectiveImports) {
                        Write-AuditLog "Importing $ModName."
                        try {
                            Import-Module $ModName -ErrorAction Stop
                            Write-AuditLog "Successfully imported $ModName." -Severity Information
                        }
                        catch {
                            Write-AuditLog "Failed to import $ModName`: $($_.Exception.Message)" -Severity Error
                            throw
                        }
                    }
                }
                else {
                    Write-AuditLog "Importing $m"
                    try {
                        Import-Module $m -ErrorAction Stop
                        Write-AuditLog "Successfully imported $m" -Severity Information
                    }
                    catch {
                        Write-AuditLog "Failed to import $m`: $($_.Exception.Message)" -Severity Error
                        throw
                    }
                }
            }
            else {
                Write-AuditLog "$m v$($installed.Version) satisfies minimum $minVersion." -Severity Information
                if ($SelectiveImports) {
                    foreach ($ModName in $SelectiveImports) {
                        Write-AuditLog "Importing SubModule: $ModName."
                        try {
                            Import-Module $ModName -ErrorAction Stop
                            Write-AuditLog "Imported SubModule: $ModName." -Severity Information
                        }
                        catch {
                            Write-AuditLog "Failed to import submodule $ModName`: $($_.Exception.Message)" -Severity Error
                            throw
                        }
                    }
                }
                else {
                    Write-AuditLog "Importing $m"
                    try {
                        Import-Module $m -ErrorAction Stop
                        Write-AuditLog "Imported $m" -Severity Information
                    }
                    catch {
                        Write-AuditLog "Failed to import $m`: $($_.Exception.Message)" -Severity Error
                        throw
                    }
                }
            }
        }
    }
    catch {
        Write-AuditLog "Module initialization failed: $($_.Exception.Message)" -Severity Error
        throw
    }
    finally { Write-AuditLog -EndFunction }
}

