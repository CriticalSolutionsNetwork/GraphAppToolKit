$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Initialize-TkAppName" {
        Context "When invalid prefix is provided" {
            It "should throw a validation error" {
                { Initialize-TkAppName -Prefix "INVALID" } | Should -Throw
            }
        }

        Context "When invalid email is provided" {
            It "should throw a validation error" {
                { Initialize-TkAppName -Prefix "MSN" -UserId "invalid-email" } | Should -Throw
            }
        }
    }
}

