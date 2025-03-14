$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Initialize-TkAppSpRegistration' {
        Mock -CommandName Write-AuditLog
        Mock -CommandName Get-ChildItem
        Mock -CommandName New-MgServicePrincipal
        Mock -CommandName Get-MgServicePrincipal
        Mock -CommandName New-MgOauth2PermissionGrant
        Context 'When AuthMethod is Certificate and CertThumbprint is not provided' {
            It 'Throws an error' {
                $AppRegistration = [PSCustomObject]@{ AppId = 'test-app-id' }
                $RequiredResourceAccessList = @()
                $Context = [PSCustomObject]@{ TenantId = 'test-tenant-id' }
                { Initialize-TkAppSpRegistration -AppRegistration $AppRegistration -RequiredResourceAccessList $RequiredResourceAccessList -Context $Context -AuthMethod 'Certificate' } | Should -Throw "CertThumbprint is required when AuthMethod is 'Certificate'."
            }
        }
        Context 'When AuthMethod is Certificate and CertThumbprint is provided' {
            It 'Retrieves the certificate and creates a service principal' {
                $AppRegistration = [PSCustomObject]@{ AppId = 'test-app-id' }
                $RequiredResourceAccessList = @()
                $Context = [PSCustomObject]@{ TenantId = 'test-tenant-id' }
                $CertThumbprint = 'test-thumbprint'
                $Cert = [PSCustomObject]@{ Thumbprint = $CertThumbprint; SubjectName = [PSCustomObject]@{ Name = 'test-cert' } }
                Mock -CommandName Get-ChildItem -MockWith { $Cert }
                Mock -CommandName Get-MgServicePrincipal -MockWith { [PSCustomObject]@{ Id = 'test-sp-id'; DisplayName = 'test-sp' } }
                Initialize-TkAppSpRegistration -AppRegistration $AppRegistration -RequiredResourceAccessList $RequiredResourceAccessList -Context $Context -AuthMethod 'Certificate' -CertThumbprint $CertThumbprint
                Assert-MockCalled -CommandName Get-ChildItem -Times 1
                Assert-MockCalled -CommandName New-MgServicePrincipal -Times 1
                Assert-MockCalled -CommandName Get-MgServicePrincipal -Times 1
            }
        }
        Context 'When AuthMethod is not Certificate' {
            It 'Throws an error for unimplemented auth methods' {
                $AppRegistration = [PSCustomObject]@{ AppId = 'test-app-id' }
                $RequiredResourceAccessList = @()
                $Context = [PSCustomObject]@{ TenantId = 'test-tenant-id' }
                { Initialize-TkAppSpRegistration -AppRegistration $AppRegistration -RequiredResourceAccessList $RequiredResourceAccessList -Context $Context -AuthMethod 'ClientSecret' } | Should -Throw "AuthMethod ClientSecret is not yet implemented."
            }
        }
        Context 'When RequiredResourceAccessList has too many resources' {
            It 'Throws an error' {
                $AppRegistration = [PSCustomObject]@{ AppId = 'test-app-id' }
                $RequiredResourceAccessList = @(
                    [PSCustomObject]@{ ResourceAppId = 'resource1'; ResourceAccess = @() },
                    [PSCustomObject]@{ ResourceAppId = 'resource2'; ResourceAccess = @() },
                    [PSCustomObject]@{ ResourceAppId = 'resource3'; ResourceAccess = @() }
                )
                $Context = [PSCustomObject]@{ TenantId = 'test-tenant-id' }
                { Initialize-TkAppSpRegistration -AppRegistration $AppRegistration -RequiredResourceAccessList $RequiredResourceAccessList -Context $Context } | Should -Throw 'Too many resources in RequiredResourceAccessList.'
            }
        }
        Context 'When RequiredResourceAccessList is valid' {
            It 'Grants the required scopes and returns the admin consent URL' {
                $AppRegistration = [PSCustomObject]@{ AppId = 'test-app-id' }
                $RequiredResourceAccessList = @(
                    [PSCustomObject]@{ ResourceAppId = 'resource1'; ResourceAccess = @() }
                )
                $Context = [PSCustomObject]@{ TenantId = 'test-tenant-id' }
                $CertThumbprint = 'test-thumbprint'
                $Cert = [PSCustomObject]@{ Thumbprint = $CertThumbprint; SubjectName = [PSCustomObject]@{ Name = 'test-cert' } }
                Mock -CommandName Get-ChildItem -MockWith { $Cert }
                Mock -CommandName Get-MgServicePrincipal -MockWith { [PSCustomObject]@{ Id = 'test-sp-id'; DisplayName = 'test-sp' } }
                Mock -CommandName New-MgOauth2PermissionGrant
                $result = Initialize-TkAppSpRegistration -AppRegistration $AppRegistration -RequiredResourceAccessList $RequiredResourceAccessList -Context $Context -AuthMethod 'Certificate' -CertThumbprint $CertThumbprint
                Assert-MockCalled -CommandName New-MgOauth2PermissionGrant -Times 1
                $result | Should -Be "https://login.microsoftonline.com/test-tenant-id/adminconsent?client_id=test-app-id"
            }
        }
    }
}

