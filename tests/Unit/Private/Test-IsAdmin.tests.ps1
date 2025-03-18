$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Test-IsAdmin" {
        Context "When the user is an administrator" {
            It "Returns True" {
                Mock -CommandName New-Object -MockWith {
                    $mockPrincipal = [PSCustomObject]@{}
                    Add-Member -InputObject $mockPrincipal -MemberType ScriptMethod -Name IsInRole -Value { return $true }
                    return $mockPrincipal
                }

                Test-IsAdmin | Should -Be $true
            }
        }

        Context "When the user is not an administrator" {
            It "Returns False" {
                Mock -CommandName New-Object -MockWith {
                    $mockPrincipal = [PSCustomObject]@{}
                    Add-Member -InputObject $mockPrincipal -MemberType ScriptMethod -Name IsInRole -Value { return $false }
                    return $mockPrincipal
                }

                Test-IsAdmin | Should -Be $false
            }
        }
    }
}

