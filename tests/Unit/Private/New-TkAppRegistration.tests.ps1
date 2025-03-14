$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "New-TkAppRegistration" {
        Mock -CommandName Get-ChildItem -MockWith {
            param ($Path)
            return @{
                Thumbprint = "ABC123"
                RawData = "MockedRawData"
            }
        }
        Mock -CommandName New-MgApplication -MockWith {
            param ($Params)
            return @{
                Id = "MockedAppId"
            }
        }
        Mock -CommandName Write-AuditLog
        Context "When creating a new app registration" {
            It "Should create a new app registration with valid parameters" {
                $DisplayName = "MyApp"
                $CertThumbprint = "ABC123"
                $Notes = "This is a sample app."
                $AppRegistration = New-TkAppRegistration -DisplayName $DisplayName -CertThumbprint $CertThumbprint -Notes $Notes
                $AppRegistration.Id | Should -Be "MockedAppId"
                Assert-MockCalled -CommandName Get-ChildItem -Exactly 1 -Scope It
                Assert-MockCalled -CommandName New-MgApplication -Exactly 1 -Scope It
            }
            It "Should throw an error if the certificate is not found" {
                Mock -CommandName Get-ChildItem -MockWith {
                    param ($Path)
                    return $null
                }
                $DisplayName = "MyApp"
                $CertThumbprint = "INVALID"
                { New-TkAppRegistration -DisplayName $DisplayName -CertThumbprint $CertThumbprint } | Should -Throw "Certificate with thumbprint INVALID not found in Cert:\CurrentUser\My."
            }
            It "Should throw an error if CertThumbprint is not provided" {
                $DisplayName = "MyApp"
                { New-TkAppRegistration -DisplayName $DisplayName } | Should -Throw "CertThumbprint is required to create an app registration. No other methods are supported yet."
            }
        }
    }
}

