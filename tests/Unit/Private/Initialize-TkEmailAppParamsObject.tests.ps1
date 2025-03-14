$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Initialize-TkEmailAppParamsObject Tests" {
        It "Should create a TkEmailAppParams object with the specified parameters" {
            # Arrange
            $AppId = "12345"
            $Id = "67890"
            $AppName = "MyEmailApp"
            $AppRestrictedSendGroup = "RestrictedGroup"
            $CertExpires = "2023-12-31"
            $CertThumbprint = "ABCDEF123456"
            $ConsentUrl = "https://consent.url"
            $DefaultDomain = "example.com"
            $SendAsUser = "user1"
            $SendAsUserEmail = "user1@example.com"
            $TenantID = "tenant123"

            # Act
            $result = Initialize-TkEmailAppParamsObject `
                -AppId $AppId `
                -Id $Id `
                -AppName $AppName `
                -AppRestrictedSendGroup $AppRestrictedSendGroup `
                -CertExpires $CertExpires `
                -CertThumbprint $CertThumbprint `
                -ConsentUrl $ConsentUrl `
                -DefaultDomain $DefaultDomain `
                -SendAsUser $SendAsUser `
                -SendAsUserEmail $SendAsUserEmail `
                -TenantID $TenantID

            # Assert
            $result | Should -BeOfType "TkEmailAppParams"
            $result.AppId | Should -Be $AppId
            $result.Id | Should -Be $Id
            $result.AppName | Should -Be $AppName
            $result.AppRestrictedSendGroup | Should -Be $AppRestrictedSendGroup
            $result.CertExpires | Should -Be $CertExpires
            $result.CertThumbprint | Should -Be $CertThumbprint
            $result.ConsentUrl | Should -Be $ConsentUrl
            $result.DefaultDomain | Should -Be $DefaultDomain
            $result.SendAsUser | Should -Be $SendAsUser
            $result.SendAsUserEmail | Should -Be $SendAsUserEmail
            $result.TenantID | Should -Be $TenantID
        }
    }
}






