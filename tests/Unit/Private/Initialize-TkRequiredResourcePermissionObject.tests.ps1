$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Initialize-TkRequiredResourcePermissionObject' {
        BeforeAll {
            # Mock the necessary cmdlets
            Mock -CommandName Get-MgServicePrincipal -MockWith {
                @{
                    AppId = '00000003-0000-0ff1-ce00-000000000000'
                }
            }
            Mock -CommandName Find-MgGraphPermission -MockWith {
                @(
                    @{ Name = 'Mail.Send'; Id = '12345' },
                    @{ Name = 'User.Read'; Id = '67890' }
                )
            }
            Mock -CommandName Write-AuditLog
        }
        Context 'When called with default parameters' {
            It 'should return a required resource permission object with Mail.Send permission' {
                $result = Initialize-TkRequiredResourcePermissionObject
                $result.RequiredResourceAccessList | Should -HaveCount 1
                $result.RequiredResourceAccessList[0].ResourceAccess | Should -Contain @{ Id = '12345'; Type = 'Role' }
            }
        }
        Context 'When called with specific GraphPermissions' {
            It 'should return a required resource permission object with specified permissions' {
                $result = Initialize-TkRequiredResourcePermissionObject -GraphPermissions 'User.Read', 'Mail.Send'
                $result.RequiredResourceAccessList | Should -HaveCount 1
                $result.RequiredResourceAccessList[0].ResourceAccess | Should -Contain @{ Id = '12345'; Type = 'Role' }
                $result.RequiredResourceAccessList[0].ResourceAccess | Should -Contain @{ Id = '67890'; Type = 'Role' }
            }
        }
        Context 'When called with Scenario 365Audit' {
            It 'should return a required resource permission object with SharePoint and Exchange permissions' {
                $result = Initialize-TkRequiredResourcePermissionObject -Scenario '365Audit'
                $result.RequiredResourceAccessList | Should -HaveCount 3
                $result.RequiredResourceAccessList[1].ResourceAccess | Should -Contain @{ Id = 'd13f72ca-a275-4b96-b789-48ebcc4da984'; Type = 'Role' }
                $result.RequiredResourceAccessList[1].ResourceAccess | Should -Contain @{ Id = '678536fe-1083-478a-9c59-b99265e6b0d3'; Type = 'Role' }
                $result.RequiredResourceAccessList[2].ResourceAccess | Should -Contain @{ Id = 'dc50a0fb-09a3-484d-be87-e023b12c6440'; Type = 'Role' }
            }
        }
        Context 'When GraphPermissions are not found' {
            BeforeAll {
                Mock -CommandName Find-MgGraphPermission -MockWith {
                    @()
                }
            }
            It 'should throw an error' {
                { Initialize-TkRequiredResourcePermissionObject -GraphPermissions 'Invalid.Permission' } | Should -Throw
            }
        }
    }
}

