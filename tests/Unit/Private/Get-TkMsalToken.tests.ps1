$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Get-TkMsalToken" {
        Context "When called with valid parameters" {
            It "Should return a valid token" {
                # Arrange
                $ClientCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                $ClientId = "12345678-1234-1234-1234-1234567890ab"
                $TenantId = "12345678-1234-1234-1234-1234567890ab"
                $Scope = "https://graph.microsoft.com/.default"
                $AuthorityType = "Global"

                # Mock Invoke-RestMethod to return a fake token response
                Mock -CommandName Invoke-RestMethod -MockWith {
                    @{
                        access_token = "fake_token"
                        expires_in = 3600
                    }
                }

                # Act
                $Token = Get-TkMsalToken -ClientCertificate $ClientCertificate -ClientId $ClientId -TenantId $TenantId -Scope $Scope -AuthorityType $AuthorityType

                # Assert
                $Token | Should -Be "fake_token"
            }
        }

        Context "When called with invalid parameters" {
            It "Should throw an error for invalid ClientId" {
                # Arrange
                $ClientCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                $ClientId = "invalid-client-id"
                $TenantId = "12345678-1234-1234-1234-1234567890ab"
                $Scope = "https://graph.microsoft.com/.default"
                $AuthorityType = "Global"

                # Act & Assert
                { Get-TkMsalToken -ClientCertificate $ClientCertificate -ClientId $ClientId -TenantId $TenantId -Scope $Scope -AuthorityType $AuthorityType } | Should -Throw
            }

            It "Should throw an error for invalid TenantId" {
                # Arrange
                $ClientCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                $ClientId = "12345678-1234-1234-1234-1234567890ab"
                $TenantId = "invalid-tenant-id"
                $Scope = "https://graph.microsoft.com/.default"
                $AuthorityType = "Global"

                # Act & Assert
                { Get-TkMsalToken -ClientCertificate $ClientCertificate -ClientId $ClientId -TenantId $TenantId -Scope $Scope -AuthorityType $AuthorityType } | Should -Throw
            }
        }

        Context "When called with different AuthorityTypes" {
            It "Should use the correct authority URL for Global" {
                # Arrange
                $ClientCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                $ClientId = "12345678-1234-1234-1234-1234567890ab"
                $TenantId = "12345678-1234-1234-1234-1234567890ab"
                $Scope = "https://graph.microsoft.com/.default"
                $AuthorityType = "Global"

                # Mock Invoke-RestMethod to return a fake token response
                Mock -CommandName Invoke-RestMethod -MockWith {
                    @{
                        access_token = "fake_token"
                        expires_in = 3600
                    }
                }

                # Act
                $Token = Get-TkMsalToken -ClientCertificate $ClientCertificate -ClientId $ClientId -TenantId $TenantId -Scope $Scope -AuthorityType $AuthorityType

                # Assert
                Assert-MockCalled -CommandName Invoke-RestMethod -Exactly 1 -Scope It -ParameterFilter {
                    $_.Uri -eq "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
                }
            }

            It "Should use the correct authority URL for AzureGov" {
                # Arrange
                $ClientCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                $ClientId = "12345678-1234-1234-1234-1234567890ab"
                $TenantId = "12345678-1234-1234-1234-1234567890ab"
                $Scope = "https://graph.microsoft.com/.default"
                $AuthorityType = "AzureGov"

                # Mock Invoke-RestMethod to return a fake token response
                Mock -CommandName Invoke-RestMethod -MockWith {
                    @{
                        access_token = "fake_token"
                        expires_in = 3600
                    }
                }

                # Act
                $Token = Get-TkMsalToken -ClientCertificate $ClientCertificate -ClientId $ClientId -TenantId $TenantId -Scope $Scope -AuthorityType $AuthorityType

                # Assert
                Assert-MockCalled -CommandName Invoke-RestMethod -Exactly 1 -Scope It -ParameterFilter {
                    $_.Uri -eq "https://login.microsoftonline.us/$TenantId/oauth2/v2.0/token"
                }
            }

            It "Should use the correct authority URL for China" {
                # Arrange
                $ClientCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                $ClientId = "12345678-1234-1234-1234-1234567890ab"
                $TenantId = "12345678-1234-1234-1234-1234567890ab"
                $Scope = "https://graph.microsoft.com/.default"
                $AuthorityType = "China"

                # Mock Invoke-RestMethod to return a fake token response
                Mock -CommandName Invoke-RestMethod -MockWith {
                    @{
                        access_token = "fake_token"
                        expires_in = 3600
                    }
                }

                # Act
                $Token = Get-TkMsalToken -ClientCertificate $ClientCertificate -ClientId $ClientId -TenantId $TenantId -Scope $Scope -AuthorityType $AuthorityType

                # Assert
                Assert-MockCalled -CommandName Invoke-RestMethod -Exactly 1 -Scope It -ParameterFilter {
                    $_.Uri -eq "https://login.chinacloudapi.cn/$TenantId/oauth2/v2.0/token"
                }
            }
        }
    }
}