$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName



Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe New-TkAppSpOauth2Registration {
        It "Should exist" {
            Test-Path function:\New-TkAppSpOauth2Registration | Should -Be $true
        }
    }
}