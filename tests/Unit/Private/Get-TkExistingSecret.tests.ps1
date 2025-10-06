$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName -Force

InModuleScope $ProjectName {
    Describe 'Get-TkExistingSecret Tests' {
        BeforeAll {
            Mock -CommandName Write-AuditLog -MockWith {  }
        }

        BeforeEach {
            # This ensures every test starts with a fresh mock of Get-Secret
            Mock -CommandName Get-Secret -MockWith { return $true }
        }

        Context 'When the secret exists' {
            BeforeEach {
                Mock -CommandName Get-Secret -MockWith { return 'MockSecretValue' }
            }

            It 'Should return $true' {
                # Act
                $result = Get-TkExistingSecret -AppName 'MyApp'
                # Assert
                $result | Should -Be $true
            }
        }

        Context 'When the secret does not exist' {
            BeforeEach {
                Mock -CommandName Get-Secret -MockWith { return $null }
            }

            It 'Should return $false' {
                $result = Get-TkExistingSecret -AppName 'MyApp'
                $result | Should -Be $false
            }
        }

        Context 'When a custom vault is specified and the secret exists' {
            BeforeEach {
                Mock -CommandName Get-Secret -MockWith {
                    param ($Name, $Vault)
                    if ($Name -eq 'MyApp' -and $Vault -eq 'CustomVault') {
                        return 'MockSecretValue'
                    }
                    return $null
                }
            }

            It 'Should return $true' {
                $result = Get-TkExistingSecret -AppName 'MyApp' -VaultName 'CustomVault'
                $result | Should -Be $true
            }
        }

        Context 'When a custom vault is specified and the secret does not exist' {
            BeforeEach {
                Mock -CommandName Get-Secret -MockWith { return $null }
            }

            It 'Should return $false' {
                $result = Get-TkExistingSecret -AppName 'MyApp' -VaultName 'CustomVault'
                $result | Should -Be $false
            }
        }
    }
}
