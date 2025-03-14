$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Initialize-TkMemPolicyManagerAppParamsObject" {
        Context "When called with valid parameters" {
            It "should return a TkMemPolicyManagerAppParams object with the correct properties" {
                # Arrange
                $AppId = "12345"
                $AppName = "MyApp"
                $CertThumbprint = "ABCDEF"
                $ObjectId = "67890"
                $ConsentUrl = "https://consent.url"
                $PermissionSet = "ReadWrite"
                $Permissions = "All"
                $TenantId = "Tenant123"
                # Act
                $result = Initialize-TkMemPolicyManagerAppParamsObject -AppId $AppId -AppName $AppName -CertThumbprint $CertThumbprint -ObjectId $ObjectId -ConsentUrl $ConsentUrl -PermissionSet $PermissionSet -Permissions $Permissions -TenantId $TenantId
                # Assert
                $result | Should -BeOfType "TkMemPolicyManagerAppParams"
                $result.AppId | Should -Be $AppId
                $result.AppName | Should -Be $AppName
                $result.CertThumbprint | Should -Be $CertThumbprint
                $result.ObjectId | Should -Be $ObjectId
                $result.ConsentUrl | Should -Be $ConsentUrl
                $result.PermissionSet | Should -Be $PermissionSet
                $result.Permissions | Should -Be $Permissions
                $result.TenantId | Should -Be $TenantId
            }
        }
        Context "When called with missing parameters" {
            It "should throw an error" {
                # Arrange
                $AppId = "12345"
                $AppName = "MyApp"
                $CertThumbprint = "ABCDEF"
                $ObjectId = "67890"
                $ConsentUrl = "https://consent.url"
                $PermissionSet = "ReadWrite"
                $Permissions = "All"
                $TenantId = "Tenant123"
                # Act & Assert
                { Initialize-TkMemPolicyManagerAppParamsObject -AppId $AppId -AppName $AppName -CertThumbprint $CertThumbprint -ObjectId $ObjectId -ConsentUrl $ConsentUrl -PermissionSet $PermissionSet -Permissions $Permissions } | Should -Throw
            }
        }
    }
}