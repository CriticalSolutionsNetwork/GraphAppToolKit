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
        Last Updated: 2025-03-16
#>
function ConvertTo-ParameterSplat {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'The object whose properties will be converted into a parameter splatting hashtable script.')]
        [ValidateNotNullOrEmpty()]
        [PSObject]$InputObject
    )
    process {
        Write-AuditLog -Message "Starting ConvertTo-ParameterSplat function." -Severity "Information"

        $splatScript = "`$params = @{`n"
        $InputObject.psobject.Properties | ForEach-Object {
            $value = $_.Value
            if ($value -is [string]) {
                $value = "`"$value`""
            }
            $splatScript += "    $($_.Name) = $value`n"
        }
        $splatScript += "}"

        Write-AuditLog -Message "Completed ConvertTo-ParameterSplat function." -Severity "Information"
        Write-Output $splatScript
    }
}
