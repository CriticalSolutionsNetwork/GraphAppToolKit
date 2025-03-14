$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Test-IsAdmin" {
        Context "When the user is an administrator" {
            It "Should return True" {
                # Mock the WindowsPrincipal and WindowsIdentity classes
                Mock -CommandName 'Security.Principal.WindowsPrincipal' -MockWith {
                    return @{
                        IsInRole = { param($role) return $role -eq [Security.Principal.WindowsBuiltinRole]::Administrator }
                    }
                }
                Mock -CommandName 'Security.Principal.WindowsIdentity::GetCurrent' -MockWith {
                    return $null
                }
                # Call the function and assert the result
                $result = Test-IsAdmin
                $result | Should -Be $true
            }
        }
        Context "When the user is not an administrator" {
            It "Should return False" {
                # Mock the WindowsPrincipal and WindowsIdentity classes
                Mock -CommandName 'Security.Principal.WindowsPrincipal' -MockWith {
                    return @{
                        IsInRole = { param($role) return $false }
                    }
                }
                Mock -CommandName 'Security.Principal.WindowsIdentity::GetCurrent' -MockWith {
                    return $null
                }
                # Call the function and assert the result
                $result = Test-IsAdmin
                $result | Should -Be $false
            }
        }
    }
}

