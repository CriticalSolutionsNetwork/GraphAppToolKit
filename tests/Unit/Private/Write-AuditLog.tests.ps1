$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Write-AuditLog" {
        Context "Basic Functionality Tests" {
            BeforeEach {
                Mock Test-IsAdmin { $true }
                Mock Get-Date { [DateTime]'2023-12-28T15:00:00' }
                Mock Read-Host { 'Y' }
                $script:LogString = @()
                Write-AuditLog -Start

            }

            It "Writes a basic information log entry" {
                { Write-AuditLog -Message "Test Message" } | Should -Not -Throw
            }

            It "Writes a warning log entry" {
                { Write-AuditLog -Message "Warning Message" -Severity 'Warning' } | Should -Not -Throw
            }

            It "Writes an error log entry" {
                { Write-AuditLog -Message "Error Message" -Severity 'Error' } | Should -Not -Throw
            }
        }

        Context "Lifecycle Management Tests" {
            BeforeEach {
                Mock Test-IsAdmin { $true }
                Mock Get-Date { [DateTime]'2023-12-28T15:00:00' }
                Mock Read-Host { 'Y' }
                Mock Export-Csv -Verifiable -MockWith {}
                $script:LogString = @()
            }

            It "Handles Start switch" {
                { Write-AuditLog -Start } | Should -Not -Throw
            }

            It "Handles BeginFunction switch" {
                { Write-AuditLog -BeginFunction } | Should -Not -Throw
            }

            It "Handles End switch with a valid OutputPath" {
                Write-AuditLog -Start
                Write-AuditLog "Test"
                # Using TestDrive for temporary file path
                $tempOutputPath = Join-Path TestDrive "auditlog_test.csv"
                { Write-AuditLog -End -OutputPath $tempOutputPath } | Should -Not -Throw
                # Asserting that Export-Csv is called. The call count might vary based on the Write-AuditLog function's implementation.
                Assert-MockCalled Export-Csv -Scope It
            }

            It "Throws an error for End switch without OutputPath" {
                Write-AuditLog -Start
                { Write-AuditLog -End } | Should -Throw
            }

            It "Handles EndFunction switch" {
                Write-AuditLog -Start
                { Write-AuditLog -EndFunction } | Should -Not -Throw
            }
        }

        Context "Error Handling Tests" {
            BeforeEach {
                Mock Test-IsAdmin { $true }
                Mock Get-Date { [DateTime]'2023-12-28T15:00:00' }
                Mock Read-Host { 'Y' }
                $script:LogString = @()
                Write-AuditLog -Start
            }

            It "Throws a parameter binding exception on invalid Severity input" {
                { Write-AuditLog -Message "Invalid Input" -Severity 'InvalidSeverity' } | Should -Throw -ErrorId "ParameterArgumentValidationError,Write-AuditLog"
            }
        }
    }
}

