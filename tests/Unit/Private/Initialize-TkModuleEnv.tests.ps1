$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Initialize-TkModuleEnv" {
        Context "When installing public modules" {
            It "Should install and import specified public modules" {
                $params = @{
                    PublicModuleNames      = "PSnmap","Microsoft.Graph"
                    PublicRequiredVersions = "1.3.1","1.23.0"
                    ImportModuleNames      = "Microsoft.Graph.Authentication", "Microsoft.Graph.Identity.SignIns"
                    Scope                  = "CurrentUser"
                }

                Mock -CommandName Install-Module -MockWith { }
                Mock -CommandName Import-Module -MockWith { }
                Mock -CommandName Write-AuditLog -MockWith { }

                Initialize-TkModuleEnv @params

                Assert-MockCalled -CommandName Install-Module -Times 2
                Assert-MockCalled -CommandName Import-Module -Times 4
            }
        }

        Context "When installing pre-release modules" {
            It "Should install and import specified pre-release modules" {
                $params = @{
                    PrereleaseModuleNames      = "Sampler", "Pester"
                    PrereleaseRequiredVersions = "2.1.5", "4.10.1"
                    Scope                      = "CurrentUser"
                }

                Mock -CommandName Install-Module -MockWith { }
                Mock -CommandName Import-Module -MockWith { }
                Mock -CommandName Write-AuditLog -MockWith { }

                Initialize-TkModuleEnv @params

                Assert-MockCalled -CommandName Install-Module -Times 2
                Assert-MockCalled -CommandName Import-Module -Times 2
            }
        }

        Context "When PowerShellGet needs to be updated" {
            It "Should update PowerShellGet if required" {
                $params = @{
                    PublicModuleNames      = "PSnmap"
                    PublicRequiredVersions = "1.3.1"
                    Scope                  = "CurrentUser"
                }

                Mock -CommandName Get-Module -MockWith {
                    return [pscustomobject]@{ Name = "PowerShellGet"; Version = [version]"1.0.0.1" }
                }
                Mock -CommandName Install-Module -MockWith { }
                Mock -CommandName Import-Module -MockWith { }
                Mock -CommandName Write-AuditLog -MockWith { }

                Initialize-TkModuleEnv @params

                Assert-MockCalled -CommandName Install-Module -Times 1
                Assert-MockCalled -CommandName Import-Module -Times 1
            }
        }

        Context "When installing modules for AllUsers scope" {
            It "Should require elevation for AllUsers scope" {
                $params = @{
                    PublicModuleNames      = "PSnmap"
                    PublicRequiredVersions = "1.3.1"
                    Scope                  = "AllUsers"
                }

                Mock -CommandName Test-IsAdmin -MockWith { return $false }
                Mock -CommandName Write-AuditLog -MockWith { }

                { Initialize-TkModuleEnv @params } | Should -Throw "Elevation required for 'AllUsers' scope."
            }
        }
    }
}

