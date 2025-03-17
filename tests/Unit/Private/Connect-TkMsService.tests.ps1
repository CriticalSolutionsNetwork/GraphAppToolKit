$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Connect-TkMsService' {
        BeforeAll {
            # Mocks are now set up once for the entire Describe block
            Mock -CommandName 'Write-AuditLog' -ModuleName GraphAppToolkit
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

                Connect-TkMsService @params

                Assert-MockCalled -CommandName 'Connect-MgGraph' -ModuleName GraphAppToolkit -Exactly -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName GraphAppToolkit -Exactly -Times 1 -Scope It -ParameterFilter { $_ -eq 'Connected to Microsoft Graph.' }
            }

            It 'Should reuse existing Microsoft Graph session if valid' {
                Mock -CommandName 'Get-MgUser' -ModuleName GraphAppToolkit -MockWith { }
                Mock -CommandName 'Get-MgContext' -ModuleName GraphAppToolkit -MockWith { @{ Scopes = @('User.Read', 'Mail.Read') } }

                $params = @{
                    MgGraph = $true
                    GraphAuthScopes = @('User.Read', 'Mail.Read')
                }

                Connect-TkMsService @params

                Assert-MockCalled -CommandName 'Get-MgUser' -ModuleName GraphAppToolkit -Exactly -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName GraphAppToolkit -Exactly -Times 1 -Scope It -ParameterFilter { $_ -eq 'Using existing Microsoft Graph session.' }
            }
        }

        Context 'When connecting to Exchange Online' {
            It 'Should connect to Exchange Online' {
                $params = @{
                    ExchangeOnline = $true
                }

                Connect-TkMsService @params

                Assert-MockCalled -CommandName 'Connect-ExchangeOnline' -ModuleName GraphAppToolkit -Exactly -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName GraphAppToolkit -Exactly -Times 1 -Scope It -ParameterFilter { $_ -eq 'Connected to Exchange Online.' }
            }

            It 'Should reuse existing Exchange Online session if valid' {
                Mock -CommandName 'Get-OrganizationConfig' -ModuleName GraphAppToolkit -MockWith { }

                $params = @{
                    ExchangeOnline = $true
                }

                Connect-TkMsService @params

                Assert-MockCalled -CommandName 'Get-OrganizationConfig' -ModuleName GraphAppToolkit -Exactly -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName GraphAppToolkit -Exactly -Times 1 -Scope It -ParameterFilter { $_ -eq 'Using existing Exchange Online session.' }
            }
        }
    }
}
