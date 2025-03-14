$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Initialize-TkAppName" {
        Context "When generating app name with mandatory parameters" {
            It "should generate app name with prefix only" {
                $env:USERDNSDOMAIN = "MyDomain"
                $result = Initialize-TkAppName -Prefix "MSN"
                $result | Should -Be "GraphToolKit-MSN-MyDomain"
            }
        }

        Context "When generating app name with optional scenario name" {
            It "should generate app name with prefix and scenario name" {
                $env:USERDNSDOMAIN = "MyDomain"
                $result = Initialize-TkAppName -Prefix "MSN" -ScenarioName "AuditGraphEmail"
                $result | Should -Be "GraphToolKit-MSN-MyDomain"
            }
        }

        Context "When generating app name with optional user email" {
            It "should generate app name with prefix and user suffix" {
                $env:USERDNSDOMAIN = "MyDomain"
                $result = Initialize-TkAppName -Prefix "MSN" -UserId "helpdesk@mydomain.com"
                $result | Should -Be "GraphToolKit-MSN-MyDomain-As-helpdesk"
            }
        }

        Context "When USERDNSDOMAIN environment variable is not set" {
            It "should fallback to default domain suffix" {
                $env:USERDNSDOMAIN = $null
                $result = Initialize-TkAppName -Prefix "MSN"
                $result | Should -Be "GraphToolKit-MSN-MyDomain"
            }
        }

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

