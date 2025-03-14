$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Write-AuditLog Tests" {
        It "Should initialize log with Start switch" {
            $script:LogString = $null
            Write-AuditLog -Start
            $script:LogString | Should -Not -BeNullOrEmpty
            $script:LogString[1].Message | Should -Match 'Begin Log'
        }
        It "Should log a message with default severity" {
            Write-AuditLog -Start
            Write-AuditLog -Message "This is a test message."
            $script:LogString | Should -Contain { $_.Message -eq "This is a test message." }
            $script:LogString[1].Severity | Should -Be "Verbose"
        }
        It "Should log a warning message" {
            Write-AuditLog -Start
            Write-AuditLog -Message "This is a warning message." -Severity "Warning"
            $script:LogString | Should -Contain { $_.Message -eq "This is a warning message." }
            $script:LogString[1].Severity | Should -Be "Warning"
        }
        It "Should log an error message" {
            Write-AuditLog -Start
            Write-AuditLog -Message "This is an error message." -Severity "Error"
            $script:LogString | Should -Contain { $_.Message -eq "This is an error message." }
            $script:LogString[1].Severity | Should -Be "Error"
        }
        It "Should log a verbose message" {
            Write-AuditLog -Start
            Write-AuditLog -Message "This is a verbose message." -Severity "Verbose"
            $script:LogString | Should -Contain { $_.Message -eq "This is a verbose message." }
            $script:LogString[1].Severity | Should -Be "Verbose"
        }
        It "Should log the beginning of a function" {
            Write-AuditLog -Start
            Write-AuditLog -BeginFunction
            $script:LogString | Should -Contain { $_.Message -Match 'Begin Function Log' }
        }
        It "Should log the end of a function" {
            Write-AuditLog -Start
            Write-AuditLog -BeginFunction
            Write-AuditLog -EndFunction
            $script:LogString | Should -Contain { $_.Message -Match 'End Function Log' }
        }
        It "Should log the end of the log and export to CSV" {
            $testPath = "TestDrive:\test.csv"
            $outputPath = $testPath
            Write-AuditLog -Start
            Write-AuditLog -End -OutputPath $outputPath
            $script:LogString | Should -Contain { $_.Message -Match 'End Log' }
            Test-Path $outputPath | Should -Be $true
            Remove-Item $outputPath
        }
        AfterEach {
            # Clean up the script-wide log variable
            Remove-Variable -Name script:LogString -ErrorAction SilentlyContinue
        }
    }
}

