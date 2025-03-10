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
