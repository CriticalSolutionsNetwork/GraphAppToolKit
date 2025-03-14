$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "New-TkExchangeEmailAppPolicy Tests" {
        Mock Write-AuditLog
        Mock Add-DistributionGroupMember
        Mock New-ApplicationAccessPolicy
        Context "When AuthorizedSenderUserName is provided" {
            It "Should add the user to the mail-enabled sending group and create a new application access policy" {
                $AppRegistration = [PSCustomObject]@{ AppId = "test-app-id" }
                $MailEnabledSendingGroup = "TestGroup"
                $AuthorizedSenderUserName = "TestUser"
                New-TkExchangeEmailAppPolicy -AppRegistration $AppRegistration -MailEnabledSendingGroup $MailEnabledSendingGroup -AuthorizedSenderUserName $AuthorizedSenderUserName
                Assert-MockCalled -CommandName Write-AuditLog -Exactly 4 -Scope It
                Assert-MockCalled -CommandName Add-DistributionGroupMember -Exactly 1 -Scope It -ParameterFilter {
                    $Identity -eq $MailEnabledSendingGroup -and $Member -eq $AuthorizedSenderUserName
                }
                Assert-MockCalled -CommandName New-ApplicationAccessPolicy -Exactly 1 -Scope It -ParameterFilter {
                    $AppId -eq $AppRegistration.AppId -and $PolicyScopeGroupId -eq $MailEnabledSendingGroup
                }
            }
        }
        Context "When AuthorizedSenderUserName is not provided" {
            It "Should create a new application access policy without adding any user to the group" {
                $AppRegistration = [PSCustomObject]@{ AppId = "test-app-id" }
                $MailEnabledSendingGroup = "TestGroup"
                New-TkExchangeEmailAppPolicy -AppRegistration $AppRegistration -MailEnabledSendingGroup $MailEnabledSendingGroup
                Assert-MockCalled -CommandName Write-AuditLog -Exactly 3 -Scope It
                Assert-MockCalled -CommandName Add-DistributionGroupMember -Exactly 0 -Scope It
                Assert-MockCalled -CommandName New-ApplicationAccessPolicy -Exactly 1 -Scope It -ParameterFilter {
                    $AppId -eq $AppRegistration.AppId -and $PolicyScopeGroupId -eq $MailEnabledSendingGroup
                }
            }
        }
        Context "When an error occurs" {
            It "Should log the error and throw" {
                $AppRegistration = [PSCustomObject]@{ AppId = "test-app-id" }
                $MailEnabledSendingGroup = "TestGroup"
                $AuthorizedSenderUserName = "TestUser"
                Mock Add-DistributionGroupMember { throw "Test error" }
                { New-TkExchangeEmailAppPolicy -AppRegistration $AppRegistration -MailEnabledSendingGroup $MailEnabledSendingGroup -AuthorizedSenderUserName $AuthorizedSenderUserName } | Should -Throw
                Assert-MockCalled -CommandName Write-AuditLog -ParameterFilter { $Message -like "Error creating Exchange Application policy: *" } -Exactly 1 -Scope It
            }
        }
    }
}

