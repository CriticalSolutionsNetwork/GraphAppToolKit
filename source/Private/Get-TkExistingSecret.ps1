<#
    .SYNOPSIS
        Checks if a secret exists in the specified secret vault.
    .PARAMETER AppName
        The name of the application for which the secret is being checked.
    .PARAMETER VaultName
        The name of the secret vault where the secret is stored. Defaults to 'GraphEmailAppLocalStore'.
    .Outputs
        [bool] $true if the secret exists, $false otherwise.
    .EXAMPLE
        $secretExists = Get-TkExistingSecret -AppName 'MyApp'
        if ($secretExists) {
            Write-Output "Secret exists."
        } else {
            Write-Output "Secret does not exist."
        }
    .NOTES
        This function uses the Get-Secret cmdlet to check for the existence of a secret in the specified vault.
#>
function Get-TkExistingSecret {
    param (
        [string]$AppName,
        [string]$VaultName = 'GraphEmailAppLocalStore'
    )
    $ExistingSecret = Get-Secret -Name "$AppName" -Vault $VaultName -ErrorAction SilentlyContinue
    if ($ExistingSecret) {
        return $true
    }
    else {
        return $false
    }
}

