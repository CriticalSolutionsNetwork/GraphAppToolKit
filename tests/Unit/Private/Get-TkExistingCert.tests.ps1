$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Get-TkExistingCert' {
        Context 'When the certificate exists' {
            It 'Should throw an error indicating the certificate already exists' {
                # Mock Get-ChildItem to return a certificate with the specified subject
                Mock -CommandName Get-ChildItem -MockWith {
                    [PSCustomObject]@{ Subject = 'CN=TestCert' }
                }
                # Mock Write-AuditLog to prevent actual logging
                Mock -CommandName Write-AuditLog
                { Get-TkExistingCert -CertName 'CN=TestCert' } | Should -Throw "Certificate with subject 'CN=TestCert' already exists in the certificate store."
                # Verify that Write-AuditLog was called with the expected messages
                Assert-MockCalled -CommandName Write-AuditLog -Exactly 6 -Scope It
            }
        }
        Context 'When the certificate does not exist' {
            It 'Should log that the certificate does not exist and continue' {
                # Mock Get-ChildItem to return no certificates
                Mock -CommandName Get-ChildItem -MockWith { @() }
                # Mock Write-AuditLog to prevent actual logging
                Mock -CommandName Write-AuditLog
                { Get-TkExistingCert -CertName 'CN=NonExistentCert' } | Should -Not -Throw
                # Verify that Write-AuditLog was called with the expected message
                Assert-MockCalled -CommandName Write-AuditLog -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Certificate with subject 'CN=NonExistentCert' does not exist in the certificate store. Continuing..." }
            }
        }
    }
}