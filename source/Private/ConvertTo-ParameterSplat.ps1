<#
    .SYNOPSIS
        Converts an object's properties to a parameter splatting hashtable script.
    .DESCRIPTION
        The ConvertTo-ParameterSplat function takes an input object and converts its properties into a PowerShell hashtable script that can be used for parameter splatting. This is useful for dynamically constructing parameter sets for cmdlets.
    .PARAMETER InputObject
        The object whose properties will be converted into a parameter splatting hashtable script. This parameter is mandatory and accepts input from the pipeline.
    .OUTPUTS
        System.String
        The function outputs a string that represents the hashtable script for parameter splatting.
    .EXAMPLE
        PS C:\> $obj = [PSCustomObject]@{ Name = "John"; Age = 30 }
        PS C:\> $obj | ConvertTo-ParameterSplat
        `$params = @{
            Name = "John"
            Age = 30
        }
    .NOTES
        Author: DrIOSx
        Date: YYYY-MM-DD
#>
function ConvertTo-ParameterSplat {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$InputObject
    )
    process {
        $splatScript = "`$params = @{`n"
        $InputObject.psobject.Properties | ForEach-Object {
            $value = $_.Value
            if ($value -is [string]) {
                $value = "`"$value`""
            }
            $splatScript += "    $($_.Name) = $value`n"
        }
        $splatScript += "}"
        Write-Output $splatScript
    }
}
