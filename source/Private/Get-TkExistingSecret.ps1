<#
.SYNOPSIS
    Checks if a secret exists in the specified vault.
.DESCRIPTION
    The Get-TkExistingSecret function checks if a secret with the specified name exists in the specified vault.
    It uses the Get-Secret cmdlet to retrieve the secret and returns $true if the secret exists, otherwise $false.
    The default vault name is 'GraphEmailAppLocalStore'.
.PARAMETER AppName
    The name of the application for which the secret is being checked.
.PARAMETER VaultName
    The name of the vault where the secret is stored. Defaults to 'GraphEmailAppLocalStore'.
.OUTPUTS
    [bool] $true if the secret exists, otherwise $false.
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

