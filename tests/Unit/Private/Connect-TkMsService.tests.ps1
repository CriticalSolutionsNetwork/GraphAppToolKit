$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Connect-TkMsService' {

        # -- Mock your own function from your module:
        Mock -CommandName 'Write-AuditLog' -ModuleName 'GraphAppToolkit'

        # -- Microsoft.Graph commands:
        Mock -CommandName 'Get-MgUser' -ModuleName 'Microsoft.Graph'
        Mock -CommandName 'Get-MgContext' -ModuleName 'Microsoft.Graph'
        Mock -CommandName 'Connect-MgGraph' -ModuleName 'Microsoft.Graph'
        Mock -CommandName 'Remove-MgContext' -ModuleName 'Microsoft.Graph'
        Mock -CommandName 'Get-MgOrganization' -ModuleName 'Microsoft.Graph'

        # -- ExchangeOnlineManagement commands:
        Mock -CommandName 'Get-OrganizationConfig' -ModuleName 'ExchangeOnlineManagement'
        Mock -CommandName 'Connect-ExchangeOnline' -ModuleName 'ExchangeOnlineManagement'
        Mock -CommandName 'Disconnect-ExchangeOnline' -ModuleName 'ExchangeOnlineManagement'

        Context 'When connecting to Microsoft Graph' {

            It 'Should connect to Microsoft Graph with specified scopes' {
                $params = @{
                    MgGraph         = $true
                    GraphAuthScopes = @('User.Read', 'Mail.Read')
                    Confirm         = $false
                }
                Connect-TkMsService @params

                # Notice the -ModuleName arguments below, matching the mocks
                Assert-MockCalled -CommandName 'Connect-MgGraph' -ModuleName 'Microsoft.Graph' -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName 'GraphAppToolkit' -Times 1 `
                    -ParameterFilter { $_ -eq 'Connected to Microsoft Graph.' }
            }

            It 'Should reuse existing Microsoft Graph session if valid' {
                Mock -CommandName 'Get-MgUser' -ModuleName 'Microsoft.Graph' -MockWith { $null }
                Mock -CommandName 'Get-MgContext' -ModuleName 'Microsoft.Graph' -MockWith { @{ Scopes = @('User.Read', 'Mail.Read') } }

                $params = @{
                    MgGraph         = $true
                    GraphAuthScopes = @('User.Read', 'Mail.Read')
                    Confirm         = $false
                }
                Connect-TkMsService @params

                Assert-MockCalled -CommandName 'Get-MgUser' -ModuleName 'Microsoft.Graph' -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName 'GraphAppToolkit' -Times 1 `
                    -ParameterFilter { $_ -eq 'An active Microsoft Graph session is detected and all required scopes are present.' }
            }
        }

        Context 'When connecting to Exchange Online' {

            It 'Should connect to Exchange Online' {
                $params = @{
                    ExchangeOnline = $true
                    Confirm        = $false
                }
                Connect-TkMsService @params

                Assert-MockCalled -CommandName 'Connect-ExchangeOnline' -ModuleName 'ExchangeOnlineManagement' -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName 'GraphAppToolkit' -Times 1 `
                    -ParameterFilter { $_ -eq 'Connected to Exchange Online.' }
            }

            It 'Should reuse existing Exchange Online session if valid' {
                # Provide a mock for Get-OrganizationConfig from ExchangeOnlineManagement
                Mock -CommandName 'Get-OrganizationConfig' -ModuleName 'ExchangeOnlineManagement' -MockWith { @{ Identity = 'TestOrg' } }

                $params = @{
                    ExchangeOnline = $true
                    Confirm        = $false
                }
                Connect-TkMsService @params

                Assert-MockCalled -CommandName 'Get-OrganizationConfig' -ModuleName 'ExchangeOnlineManagement' -Times 1
                Assert-MockCalled -CommandName 'Write-AuditLog' -ModuleName 'GraphAppToolkit' -Times 1 `
                    -ParameterFilter { $_ -eq 'An active Exchange Online session is detected.' }
            }
        }
    }
}
