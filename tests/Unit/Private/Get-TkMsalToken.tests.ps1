$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Get-TkMsalToken' {
        BeforeAll {
            Mock -CommandName Write-AuditLog -MockWith { $null }
        }

        BeforeEach {
            class X509Certificate2 {
                [datetime]$NotAfter
                [string]$Thumbprint

                X509Certificate2 ([datetime]$expiryDate) {
                    $this.NotAfter = $expiryDate
                    $this.Thumbprint = "ABC123456789DEF"
                }

                [byte[]] GetCertHash() {
                    return (1..20)
                }
            }

            # Mock an X.509 Certificate using our MockX509Certificate2 class
            $ClientCertificate = [X509Certificate2]::new((Get-Date).AddDays(30))  # Valid certificate (expires in 30 days)

            # Define functions for proper mocking
            function GetCertHash {}
            function GetRSAPrivateKey {}

            # Mock GetRSAPrivateKey to return an RSA object
            Mock -CommandName GetRSAPrivateKey -MockWith {
                $MockRSA = New-Object System.Security.Cryptography.RSACryptoServiceProvider
                return $MockRSA
            }

            # Mock Invoke-RestMethod to return a fake token response
            Mock -CommandName Invoke-RestMethod -MockWith {
                @{
                    access_token = 'fake_token'
                    expires_in   = 3600
                }
            }
        }

        Context "When called with a valid certificate" {
            It "Should return a valid token" {
                $ClientId = "12345678-1234-1234-1234-1234567890ab"
                $TenantId = "12345678-1234-1234-1234-1234567890ab"
                $Scope = "https://graph.microsoft.com/.default"
                $AuthorityType = "Global"

                $Token = Get-TkMsalToken -ClientCertificate $ClientCertificate -ClientId $ClientId -TenantId $TenantId -Scope $Scope -AuthorityType $AuthorityType

                $Token | Should -Be "fake_token"
            }
        }

        Context "When called with an expired certificate" {
            BeforeEach {
                # Use a new instance with expired date
                $ClientCertificate = [MockX509Certificate2]::new((Get-Date).AddDays(-1))
            }

            It "Should throw an error for expired certificate" {
                $ClientId = "12345678-1234-1234-1234-1234567890ab"
                $TenantId = "12345678-1234-1234-1234-1234567890ab"
                $Scope = "https://graph.microsoft.com/.default"
                $AuthorityType = "Global"

                { Get-TkMsalToken -ClientCertificate $ClientCertificate -ClientId $ClientId -TenantId $TenantId -Scope $Scope -AuthorityType $AuthorityType } | Should -Throw "Certificate has expired."
            }
        }

        Context 'When called with invalid parameters' {
            It 'Should throw an error for invalid ClientId' {
                $ClientCertificate = [MockX509Certificate2]::new((Get-Date).AddDays(30))  # Valid certificate
                $ClientId = 'invalid-client-id'
                $TenantId = '12345678-1234-1234-1234-1234567890ab'
                $Scope = 'https://graph.microsoft.com/.default'
                $AuthorityType = 'Global'

                { Get-TkMsalToken -ClientCertificate $ClientCertificate -ClientId $ClientId -TenantId $TenantId -Scope $Scope -AuthorityType $AuthorityType } | Should -Throw
            }

            It 'Should throw an error for invalid TenantId' {
                $ClientCertificate = [MockX509Certificate2]::new((Get-Date).AddDays(30))  # Valid certificate
                $ClientId = '12345678-1234-1234-1234-1234567890ab'
                $TenantId = 'invalid-tenant-id'
                $Scope = 'https://graph.microsoft.com/.default'
                $AuthorityType = 'Global'

                { Get-TkMsalToken -ClientCertificate $ClientCertificate -ClientId $ClientId -TenantId $TenantId -Scope $Scope -AuthorityType $AuthorityType } | Should -Throw
            }
        }
    }
}