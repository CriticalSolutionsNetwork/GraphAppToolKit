$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName



Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe ConvertTo-ParameterSplat {
        It "Should exist" {
            Test-Path function:\ConvertTo-ParameterSplat | Should -Be $true
        }
    }
}