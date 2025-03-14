$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'ConvertTo-ParameterSplat' {
        It 'should convert object properties to a parameter splatting hashtable script' {
            $obj = [PSCustomObject]@{ Name = 'John'; Age = 30 }
            $expected = @'
$params = @{
    Name = "John"
    Age = 30
}
'@
            $result = $obj | ConvertTo-ParameterSplat
            $result | Should -BeExactly $expected
        }
        It 'should handle string properties correctly' {
            $obj = [PSCustomObject]@{ City = 'New York'; Country = 'USA' }
            $expected = @'
$params = @{
    City = "New York"
    Country = "USA"
}
'@
            $result = $obj | ConvertTo-ParameterSplat
            $result | Should -BeExactly $expected
        }
        It 'should handle numeric properties correctly' {
            $obj = [PSCustomObject]@{ Width = 1920; Height = 1080 }
            $expected = @'
$params = @{
    Width = 1920
    Height = 1080
}
'@
            $result = $obj | ConvertTo-ParameterSplat
            $result | Should -BeExactly $expected
        }
        It 'should handle mixed property types correctly' {
            $obj = [PSCustomObject]@{ Name = 'Alice'; Age = 25; IsActive = $true }
            $expected = @'
$params = @{
    Name = "Alice"
    Age = 25
    IsActive = True
}
'@
            $result = $obj | ConvertTo-ParameterSplat
            $result | Should -BeExactly $expected
        }
        It 'should handle empty objects correctly' {
            $obj = [PSCustomObject]@{}
            $expected = @'
$params = @{
}
'@
            $result = $obj | ConvertTo-ParameterSplat
            $result | Should -BeExactly $expected
        }
    }
}

