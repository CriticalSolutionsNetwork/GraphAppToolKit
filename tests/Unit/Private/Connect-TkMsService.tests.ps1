$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Connect-TkMsService' {
        BeforeAll {
            function Get-OrganizationConfig {}
            function Remove-MgContext {}
            # Mock external dependency commands to avoid real Graph/Exchange calls for each test
            Mock Connect-MgGraph -ModuleName GraphAppToolkit -MockWith { $null }
            Mock Connect-ExchangeOnline -ModuleName GraphAppToolkit -MockWith { $null }
            Mock Get-MgUser -ModuleName GraphAppToolkit -MockWith { $null }
            Mock Get-OrganizationConfig -ModuleName GraphAppToolkit -MockWith { throw 'No EXO session' }
            Mock Get-MgContext -ModuleName GraphAppToolkit -MockWith { throw }
            Mock Get-MgOrganization -ModuleName GraphAppToolkit -MockWith { [PSCustomObject]@{ DisplayName = 'DummyOrg' } }
            Mock Remove-MgContext -ModuleName GraphAppToolkit -MockWith { $null }
            Mock Disconnect-ExchangeOnline -ModuleName GraphAppToolkit -MockWith { $null }
            Mock Write-AuditLog -MockWith { $null }
        }

        Context 'When only the -MgGraph switch is used' {
            It 'calls Connect-MgGraph and not Connect-ExchangeOnline' {
                # Act: call function with MgGraph switch
                Connect-TkMsService -MgGraph -GraphAuthScopes @('User.Read') -Confirm:$false

                # Assert: Connect-MgGraph was called once; Connect-ExchangeOnline was not called
                Assert-MockCalled Connect-MgGraph -ModuleName GraphAppToolkit -Times 1
                Assert-MockCalled Connect-ExchangeOnline -ModuleName GraphAppToolkit -Times 0
            }
        }
        Context "When only the -ExchangeOnline switch is used" {
            It "calls Connect-ExchangeOnline and not Connect-MgGraph" {
                # Act: call function with ExchangeOnline switch
                Connect-TkMsService -ExchangeOnline -Confirm:$false

                # Assert: Connect-ExchangeOnline was called once; Connect-MgGraph was not called
                Assert-MockCalled Connect-ExchangeOnline -Times 1
                Assert-MockCalled Connect-MgGraph        -Times 0
            }
        }

        Context "When both -MgGraph and -ExchangeOnline switches are used" {
            It "calls both Connect-MgGraph and Connect-ExchangeOnline" {
                # Act: call function with both switches
                Connect-TkMsService -MgGraph -GraphAuthScopes @('User.Read') -ExchangeOnline -Confirm:$false

                # Assert: Both Connect-MgGraph and Connect-ExchangeOnline were called once
                Assert-MockCalled Connect-MgGraph        -Times 1
                Assert-MockCalled Connect-ExchangeOnline -Times 1
            }
        }

        Context "When no switch is specified" {
            It "does not call any Connect commands" {
                # Act: call function with no switches
                Connect-TkMsService -Confirm:$false

                # Assert: Neither Connect-MgGraph nor Connect-ExchangeOnline was called
                Assert-MockCalled Connect-MgGraph        -Times 0
                Assert-MockCalled Connect-ExchangeOnline -Times 0
            }
        }
        Context "When Microsoft Graph connection fails" {
            BeforeEach {
                Mock Connect-MgGraph -ModuleName GraphAppToolkit -MockWith { throw "Graph API Failure" }
            }

            It "throws an error and logs the failure" {
                { Connect-TkMsService -MgGraph -GraphAuthScopes @('User.Read') -Confirm:$false } | Should -Throw "Graph API Failure"
                Assert-MockCalled Write-AuditLog -Times 1
            }
        }

    }
}

