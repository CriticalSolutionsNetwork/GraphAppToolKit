$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Initialize-TkAppAuthCertificate' {
        Context 'When retrieving an existing certificate by thumbprint' {
            It 'Should retrieve the certificate if it exists' {
                # Arrange
                $thumbprint = 'ABC123DEF456'
                $cert = New-Object PSCustomObject -Property @{
                    Thumbprint = $thumbprint
                    NotAfter   = (Get-Date).AddYears(1)
                }
                Mock -CommandName Get-ChildItem -MockWith {
                    $cert
                }

                # Act
                $result = Initialize-TkAppAuthCertificate -Thumbprint $thumbprint -Confirm:$false

                # Assert
                $result.CertThumbprint | Should -Be $thumbprint
                $result.CertExpires | Should -Be $cert.NotAfter.ToString('yyyy-MM-dd HH:mm:ss')
            }

            It 'Should throw an error if the certificate does not exist' {
                # Arrange
                $thumbprint = 'NONEXISTENT'
                Mock -CommandName Get-ChildItem -MockWith {
                    $null
                }

                # Act & Assert
                { Initialize-TkAppAuthCertificate -Thumbprint $thumbprint -Confirm:$false } | Should -Throw "Certificate with thumbprint $thumbprint not found in Cert:\CurrentUser\My."
            }
        }

        Context 'When creating a new self-signed certificate' {
            It 'Should create a new certificate if no thumbprint is provided' {
                # Arrange
                $subject = 'CN=MyAppCert'
                $cert = New-Object PSCustomObject -Property @{
                    Thumbprint = 'NEWCERT123'
                    NotAfter   = (Get-Date).AddYears(1)
                }
                Mock -CommandName New-SelfSignedCertificate -MockWith  {
                    $cert
                }
                Mock -CommandName Get-TkExistingCert -MockWith {}

                # Act
                $result = Initialize-TkAppAuthCertificate -Subject $subject -Confirm:$false

                # Assert
                $result.CertThumbprint | Should -Be $cert.Thumbprint
                $result.CertExpires | Should -Be $cert.NotAfter.ToString('yyyy-MM-dd HH:mm:ss')
            }

            It 'Should include AppName in the output if provided' {
                # Arrange
                $subject = 'CN=MyAppCert'
                $appName = 'MyApp'
                $cert = New-Object PSCustomObject -Property @{
                    Thumbprint = 'NEWCERT123'
                    NotAfter   = (Get-Date).AddYears(1)
                }
                Mock -CommandName New-SelfSignedCertificate -MockWith {
                    $cert
                }
                Mock -CommandName Get-TkExistingCert -MockWith {}

                # Act
                $result = Initialize-TkAppAuthCertificate -Subject $subject -AppName $appName -Confirm:$false

                # Assert
                $result.CertThumbprint | Should -Be $cert.Thumbprint
                $result.CertExpires | Should -Be $cert.NotAfter.ToString('yyyy-MM-dd HH:mm:ss')
                $result.AppName | Should -Be $appName
            }

            It 'Should throw an error if certificate creation is skipped by user confirmation' {
                # Arrange
                Mock -CommandName New-SelfSignedCertificate -MockWith {
                    throw 'Certificate creation was skipped by user confirmation.'
                }
                Mock -CommandName Get-TkExistingCert -MockWith {}

                # Act & Assert
                { Initialize-TkAppAuthCertificate -Subject 'CN=MyAppCert' -Confirm:$false } | Should -Throw 'Certificate creation was skipped by user confirmation.'
            }
        }
    }
}

