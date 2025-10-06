$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
}).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Connect-TkMsService' {
        BeforeAll {
            # Mock external cmdlets
            function Get-MgUser { $false }
            function Get-MgContext {  }
            function Connect-MgGraph { }
            function Remove-MgContext { }
            function Get-OrganizationConfig { }
            function Connect-ExchangeOnline { }
            function Disconnect-ExchangeOnline { }
            Mock -CommandName 'Get-MgUser' -MockWith { @{} }
            Mock -CommandName 'Get-MgContext' -MockWith { @{ Scopes = @('User.Read') } }
            Mock -CommandName 'Connect-MgGraph' -MockWith { }
            Mock -CommandName 'Remove-MgContext' -MockWith { }
            Mock -CommandName 'Get-OrganizationConfig' -MockWith { @{} }
            Mock -CommandName 'Connect-ExchangeOnline' -MockWith { }
            Mock -CommandName 'Disconnect-ExchangeOnline' -MockWith { }
        }
        Context 'When connecting to Microsoft Graph' {
            It 'Connects to Microsoft Graph when -MgGraph is specified' {
                Connect-TkMsService -MgGraph -GraphAuthScopes 'User.Read' -Confirm:$false
                Assert-MockCalled -CommandName 'Connect-MgGraph' -Exactly -Times 1
            }
        }
        Context 'When connecting to Exchange Online' {
            It 'Connects to Exchange Online when -ExchangeOnline is specified' {
                Connect-TkMsService -ExchangeOnline -Confirm:$false
                Assert-MockCalled -CommandName 'Connect-ExchangeOnline' -Exactly -Times 1
            }
        }
        Context 'When connecting to both services' {
            It 'Connects to both Microsoft Graph and Exchange Online when both switches are specified' {
                Connect-TkMsService -MgGraph -GraphAuthScopes 'User.Read' -ExchangeOnline -Confirm:$false
                Assert-MockCalled -CommandName 'Connect-MgGraph' -Exactly -Times 1
                Assert-MockCalled -CommandName 'Connect-ExchangeOnline' -Exactly -Times 1
            }
        }
        Context 'When no switches are specified' {
            It 'Does not connect to any service when no switches are specified' {
                Connect-TkMsService -Confirm:$false
                Assert-MockCalled -CommandName 'Connect-MgGraph' -Exactly -Times 0
                Assert-MockCalled -CommandName 'Connect-ExchangeOnline' -Exactly -Times 0
            }
        }
    }
}
