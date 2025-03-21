@{
    PSDependOptions             = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
            Repository = 'PSGallery'
        }
    }

    InvokeBuild                 = 'latest'
    PSScriptAnalyzer            = 'latest'
    Pester                      = 'latest'
    ModuleBuilder               = 'latest'
    ChangelogManagement         = 'latest'
    Sampler                     = 'latest'
    'Sampler.GitHubTasks'       = 'latest'
    'Microsoft.Graph' = 'latest'
    'ExchangeOnlineManagement'  = 'latest'
    'Microsoft.PowerShell.SecretManagement' = 'latest'
    'SecretManagement.JustinGrote.CredMan' = 'latest'
}
