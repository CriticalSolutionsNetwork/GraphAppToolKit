$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Initialize-TkM365AuditAppParamsObject Tests" {
        It "Should initialize TkM365AuditAppParams object with valid parameters" {
            # Arrange
            $AppName = "MyApp"
            $AppId = "12345"
            $ObjectId = "67890"
            $TenantId = "tenant123"
            $CertThumbprint = "ABCDEF"
            $CertExpires = "2023-12-31"
            $ConsentUrl = "https://consent.url"
            $MgGraphPermissions = @("Permission1", "Permission2")
            $SharePointPermissions = @("Permission1")
            $ExchangePermissions = @("Permission1", "Permission2")

            # Act
            $result = Initialize-TkM365AuditAppParamsObject -AppName $AppName -AppId $AppId -ObjectId $ObjectId -TenantId $TenantId -CertThumbprint $CertThumbprint -CertExpires $CertExpires -ConsentUrl $ConsentUrl -MgGraphPermissions $MgGraphPermissions -SharePointPermissions $SharePointPermissions -ExchangePermissions $ExchangePermissions

            # Assert
            $result | Should -BeOfType "TkM365AuditAppParams"
            $result.AppName | Should -Be $AppName
            $result.AppId | Should -Be $AppId
            $result.ObjectId | Should -Be $ObjectId
            $result.TenantId | Should -Be $TenantId
            $result.CertThumbprint | Should -Be $CertThumbprint
            $result.CertExpires | Should -Be $CertExpires
            $result.ConsentUrl | Should -Be $ConsentUrl
            $result.MgGraphPermissions | Should -Be $MgGraphPermissions
            $result.SharePointPermissions | Should -Be $SharePointPermissions
            $result.ExchangePermissions | Should -Be $ExchangePermissions
        }

        It "Should throw an error when required parameters are missing" {
            # Arrange
            $AppName = "MyApp"
            $AppId = "12345"
            $ObjectId = "67890"
            $TenantId = "tenant123"
            $CertThumbprint = "ABCDEF"
            $CertExpires = "2023-12-31"
            $ConsentUrl = "https://consent.url"
            $MgGraphPermissions = @("Permission1", "Permission2")
            $SharePointPermissions = @("Permission1")
            $ExchangePermissions = @("Permission1", "Permission2")

            # Act & Assert
            { Initialize-TkM365AuditAppParamsObject -AppId $AppId -ObjectId $ObjectId -TenantId $TenantId -CertThumbprint $CertThumbprint -CertExpires $CertExpires -ConsentUrl $ConsentUrl -MgGraphPermissions $MgGraphPermissions -SharePointPermissions $SharePointPermissions -ExchangePermissions $ExchangePermissions } | Should -Throw
        }
    }
}