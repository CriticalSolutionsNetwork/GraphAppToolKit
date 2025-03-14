$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Set-TkJsonSecret' {
        Mock -CommandName Get-SecretVault -MockWith { return @() }
        Mock -CommandName Register-SecretVault
        Mock -CommandName Get-SecretInfo -MockWith { return $null }
        Mock -CommandName Remove-Secret
        Mock -CommandName Set-Secret
        Mock -CommandName Write-AuditLog
        Context 'When the vault is not registered' {
            It 'Should register the vault' {
                Set-TkJsonSecret -Name 'TestSecret' -InputObject @{ Key = 'Value' } -Confirm:$false
                Assert-MockCalled -CommandName Register-SecretVault -Exactly 1 -Scope It
            }
        }
        Context 'When the vault is already registered' {
            Mock -CommandName Get-SecretVault -MockWith { return @{ Name = 'GraphEmailAppLocalStore' } }
            It 'Should not register the vault again' {
                Set-TkJsonSecret -Name 'TestSecret' -InputObject @{ Key = 'Value' } -Confirm:$false
                Assert-MockCalled -CommandName Register-SecretVault -Exactly 0 -Scope It
            }
        }
        Context 'When the secret does not exist' {
            It 'Should store the secret' {
                Set-TkJsonSecret -Name 'TestSecret' -InputObject @{ Key = 'Value' } -Confirm:$false
                Assert-MockCalled -CommandName Set-Secret -Exactly 1 -Scope It
            }
        }
        Context 'When the secret already exists and Overwrite is not specified' {
            Mock -CommandName Get-SecretInfo -MockWith { return @{ Name = 'TestSecret' } }
            It 'Should throw an error' {
                { Set-TkJsonSecret -Name 'TestSecret' -InputObject @{ Key = 'Value' } -Confirm:$false } | Should -Throw
            }
        }
        Context 'When the secret already exists and Overwrite is specified' {
            Mock -CommandName Get-SecretInfo -MockWith { return @{ Name = 'TestSecret' } }
            It 'Should overwrite the secret' {
                Set-TkJsonSecret -Name 'TestSecret' -InputObject @{ Key = 'Value' } -Overwrite -Confirm:$false
                Assert-MockCalled -CommandName Remove-Secret -Exactly 1 -Scope It
                Assert-MockCalled -CommandName Set-Secret -Exactly 1 -Scope It
            }
        }
    }
}

