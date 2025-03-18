$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Connect-TkMsService' {
        BeforeAll {
            # Define the functions before mocking them
            function Write-AuditLog { }
            function Get-MgUser { }
            function Get-MgContext { }
            function Get-MgOrganization { }
            function Remove-MgContext { }
            function Connect-MgGraph { }
            function Get-OrganizationConfig { }
            function Disconnect-ExchangeOnline { }
            function Connect-ExchangeOnline { }

            # Mocks are now set up once for the entire Describe block
            Mock -CommandName 'Write-AuditLog' -MockWith {
                Write-Host "Audit log: $_"
            } -ModuleName GraphAppToolkit
            Mock -CommandName 'Get-MgUser' -ModuleName GraphAppToolkit
            Mock -CommandName 'Get-MgContext' -ModuleName GraphAppToolkit
            Mock -CommandName 'Get-MgOrganization' -ModuleName GraphAppToolkit
            Mock -CommandName 'Remove-MgContext' -ModuleName GraphAppToolkit
            Mock -CommandName 'Connect-MgGraph' -ModuleName GraphAppToolkit
            Mock -CommandName 'Get-OrganizationConfig' -ModuleName GraphAppToolkit
            Mock -CommandName 'Disconnect-ExchangeOnline' -ModuleName GraphAppToolkit
            Mock -CommandName 'Connect-ExchangeOnline' -ModuleName GraphAppToolkit
        }

        Context 'When connecting to Microsoft Graph' {
            It 'Should connect to Microsoft Graph with specified scopes' {
                $params = @{
                    MgGraph = $true
                    GraphAuthScopes = @('User.Read', 'Mail.Read')
                }

                Connect-TkMsService @params -Confirm:$false

                Assert-MockCalled -CommandName 'Connect-MgGraph' -ModuleName GraphAppToolkit -Exactly -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName GraphAppToolkit -Exactly -Times 1 -Scope It -ParameterFilter { $_ -eq 'Connected to Microsoft Graph.' }
            }

            It 'Should reuse existing Microsoft Graph session if valid' {
                Mock -CommandName 'Get-MgUser' -ModuleName GraphAppToolkit -MockWith { }
                Mock -CommandName 'Get-MgContext' -ModuleName GraphAppToolkit -MockWith { @{ Scopes = @('User.Read', 'Mail.Read') } }
                Mock -CommandName 'Get-MgOrganization' -ModuleName GraphAppToolkit -MockWith { @{ DisplayName = 'TestOrg' } }

                $params = @{
                    MgGraph = $true
                    GraphAuthScopes = @('User.Read', 'Mail.Read')
                }

                Connect-TkMsService @params -Confirm:$false

                Assert-MockCalled -CommandName 'Get-MgUser' -ModuleName GraphAppToolkit -Exactly -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName GraphAppToolkit -Exactly -Times 1 -Scope It -ParameterFilter { $_ -like '*Using existing Microsoft Graph session*' }
            }

            It 'Should create a new Microsoft Graph session if existing session is invalid' {
                Mock -CommandName 'Get-MgUser' -ModuleName GraphAppToolkit -MockWith { throw "Invalid session" }
                Mock -CommandName 'Connect-MgGraph' -ModuleName GraphAppToolkit -MockWith { }

                $params = @{
                    MgGraph = $true
                    GraphAuthScopes = @('User.Read', 'Mail.Read')
                }

                Connect-TkMsService @params -Confirm:$false

                Assert-MockCalled -CommandName 'Connect-MgGraph' -ModuleName GraphAppToolkit -Exactly -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName GraphAppToolkit -Exactly -Times 1 -Scope It -ParameterFilter { $_ -eq 'Connected to Microsoft Graph.' }
            }
        }

        Context 'When connecting to Exchange Online' {
            It 'Should connect to Exchange Online' {
                $params = @{
                    ExchangeOnline = $true
                }

                Connect-TkMsService @params -Confirm:$false

                Assert-MockCalled -CommandName 'Connect-ExchangeOnline' -ModuleName GraphAppToolkit -Exactly -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName GraphAppToolkit -Exactly -Times 1 -Scope It -ParameterFilter { $_ -eq 'Connected to Exchange Online.' }
            }

            It 'Should reuse existing Exchange Online session if valid' {
                Mock -CommandName 'Get-OrganizationConfig' -ModuleName GraphAppToolkit -MockWith { @{ DisplayName = 'TestOrg' } }

                $params = @{
                    ExchangeOnline = $true
                }

                Connect-TkMsService @params -Confirm:$false

                Assert-MockCalled -CommandName 'Get-OrganizationConfig' -ModuleName GraphAppToolkit -Exactly -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName GraphAppToolkit -Exactly -Times 1 -Scope It -ParameterFilter { $_ -eq 'Using existing Exchange Online session.' }
            }

            It 'Should create a new Exchange Online session if existing session is invalid' {
                Mock -CommandName 'Get-OrganizationConfig' -ModuleName GraphAppToolkit -MockWith { throw "Invalid session" }
                Mock -CommandName 'Connect-ExchangeOnline' -ModuleName GraphAppToolkit -MockWith { }

                $params = @{
                    ExchangeOnline = $true
                }

                Connect-TkMsService @params -Confirm:$false

                Assert-MockCalled -CommandName 'Connect-ExchangeOnline' -ModuleName GraphAppToolkit -Exactly -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName GraphAppToolkit -Exactly -Times 1 -Scope It -ParameterFilter { $_ -eq 'Connected to Exchange Online.' }
            }
        }
    }
}
