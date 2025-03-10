function New-TkRequiredResourcePermissionObject {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Application (app-only) permissions for Microsoft Graph.'
        )]
        [string[]]
        $GraphPermissions = @('Mail.Send'),
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Scenario app version.',
            ParameterSetName = 'Scenario'
        )]
        [ValidateSet('365Audit')]
        [string]
        $Scenario
    )
    process {
        if (-not $script:LogString) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }
        try {
            Write-AuditLog '###############################################'
            ## 1) Retrieve service principals by DisplayName
            Write-AuditLog 'Looking up service principals by display name...'
            $spGraph = Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft Graph'"
            # 2) Build an array of [MicrosoftGraphRequiredResourceAccess] objects
            $requiredResourceAccessList = @()
            # Retrieve all application permissions
            $permissionList = Find-MgGraphPermission -PermissionType Application -All
            # region Graph perms
            [Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess] $graphRra = $null
            # If GraphPermissions is not null or empty, process them
            if ($GraphPermissions -and $GraphPermissions.Count -gt 0) {
                if (-not $spGraph) {
                    throw 'Microsoft Graph Service Principal not found (by display name).'
                }
                Write-AuditLog "Gathering permissions: $($GraphPermissions -join ', ')"
                $graphRra = [Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess]::new()
                $graphRra.ResourceAppId = $spGraph.AppId
                foreach ($permName in $GraphPermissions) {
                    $foundPerm = $permissionList | Where-Object { $_.Name -eq $permName } #Find-MgGraphPermission -PermissionType Application -All |
                    if ($foundPerm) {
                        # If multiple matches, pick the first
                        $graphRra.ResourceAccess += @{ Id = $foundPerm.Id; Type = 'Role' }
                        Write-AuditLog "Found Graph permission ID for '$permName': $($foundPerm[0].Id)"
                    }
                    else {
                        Write-AuditLog -Severity Warning -Message "Graph Permission '$permName' not found!"
                    }
                }
                if ($graphRra.ResourceAccess) {
                    $requiredResourceAccessList += $graphRra
                }
                else {
                    throw "No Graph permissions found for '$($GraphPermissions -join ', ')'. Check the permission names and try again."
                }
            }
            # endregion
            # region Scenario-specific permissions
            # Scenario 365Audit
            if ($Scenario -eq '365Audit') {
                # region SharePoint perms
                [Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess] $spRra = $null
                $spRra = [Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess]::new()
                $spRra.ResourceAppId = "00000003-0000-0ff1-ce00-000000000000" # SharePoint Online
                $spRra.ResourceAccess += @{ Id = 'd13f72ca-a275-4b96-b789-48ebcc4da984'; Type = 'Role' }
                $spRra.ResourceAccess += @{ Id = '678536fe-1083-478a-9c59-b99265e6b0d3'; Type = 'Role' }
                $requiredResourceAccessList += $spRra
                # endregion
                # region Exchange perms
                [Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess] $spRra = $null
                $exRra = [Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess]::new()
                $exRra.ResourceAppId = "00000002-0000-0ff1-ce00-000000000000" # Exchange Online
                $exRra.ResourceAccess += @{ Id = 'dc50a0fb-09a3-484d-be87-e023b12c6440'; Type = 'Role' }
                $requiredResourceAccessList += $exRra
            } # endregion Scenario 365Audit
            # endregion Scenario-specific permissions
            # 3) Build final result object
            $result = [PSCustomObject]@{
                RequiredResourceAccessList = $requiredResourceAccessList
            }
            # }
            Write-AuditLog 'Returning context object.'
            return $result
        }
        catch {
            throw
        }
        finally {
            Write-AuditLog -EndFunction
        }
    }
}
