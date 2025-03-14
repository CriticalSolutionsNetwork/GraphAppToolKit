<#
    .SYNOPSIS
    Stores a JSON representation of an object as a secret in a specified vault.
    .DESCRIPTION
    The Set-TkJsonSecret function converts a given object to JSON format and stores it as a secret in a specified vault.
    If the vault is not registered, it will be auto-registered using the specified vault module.
    The function supports overwriting existing secrets if the -Overwrite switch is specified.
    .PARAMETER Name
    The name under which to store the secret. This parameter is mandatory.
    .PARAMETER InputObject
    The object to convert to JSON and store. This parameter is mandatory.
    .PARAMETER VaultName
    The name of the vault where the secret will be stored. Defaults to 'GraphEmailAppLocalStore'.
    .PARAMETER VaultModuleName
    The name of the vault module to use if auto-registering the vault. Defaults to 'SecretManagement.JustinGrote.CredMan'.
    .PARAMETER Overwrite
    Switch to overwrite an existing secret of the same name without prompting.
    .EXAMPLE
    Set-TkJsonSecret -Name 'MySecret' -InputObject $myObject
    This example converts the object stored in $myObject to JSON and stores it as a secret named 'MySecret' in the default vault.
    .EXAMPLE
    Set-TkJsonSecret -Name 'MySecret' -InputObject $myObject -VaultName 'MyCustomVault' -VaultModuleName 'MyVaultModule' -Overwrite
    This example converts the object stored in $myObject to JSON and stores it as a secret named 'MySecret' in the 'MyCustomVault' vault, using 'MyVaultModule' for auto-registration if needed, and overwrites any existing secret with the same name.
    .NOTES
    If the specified vault is not registered, it will be auto-registered using the specified vault module.
    If the secret already exists and the -Overwrite switch is not specified, an error will be thrown.
#>
function Set-TkJsonSecret {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([string])]
    param(
        [Parameter(
            Mandatory = $true, HelpMessage = 'The name under which to store the secret.'
        )]
        [string]
        $Name,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The object to convert to JSON and store.'
        )]
        [PSObject]
        $InputObject,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Name of the vault. Defaults to GraphEmailAppLocalStore.'
        )]
        [string]
        $VaultName = 'GraphEmailAppLocalStore',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Name of the vault module to use if auto-registering. Defaults to SecretManagement.JustinGrote.CredMan.'
        )]
        [string]
        $VaultModuleName = 'SecretManagement.JustinGrote.CredMan',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Overwrite existing secret of the same name without prompting.'
        )]
        [switch]
        $Overwrite
    )
    if (!($script:LogString)) { Write-AuditLog -Start }else { Write-AuditLog -BeginFunction }
    try {
        Write-AuditLog '###############################################'
        # Auto-register vault if missing
        if (!(Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue)) {
            Write-AuditLog -Message "Registering $VaultName using $VaultModuleName"
            Register-SecretVault -Name $VaultName -ModuleName $VaultModuleName -ErrorAction Stop
            Write-AuditLog -Message "Vault '$VaultName' registered."
        }
        else {
            Write-AuditLog "Vault '$VaultName' is already registered."
        }
        # Check if secret already exists
        $secretExists = (Get-SecretInfo -Name $Name -Vault $VaultName -ErrorAction SilentlyContinue)
        if ($secretExists) {
            if ($Overwrite) {
                $shouldProcessOperation = 'Remove-Secret'
                $shouldProcessTarget = "Name: '$Name' in vault '$VaultName'."
                if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
                    Write-AuditLog -Message "Overwriting existing secret '$Name' in vault '$VaultName'."
                    Remove-Secret -Name $Name -Vault $VaultName -Confirm:$false -ErrorAction Stop
                }
                else {
                    Write-AuditLog -Message "Overwrite of existing secret '$Name' in vault '$VaultName' was cancelled." -Severity Warning
                    throw
                }
            }
            else {
                Write-AuditLog -Message "Secret '$Name' already exists. Remove it or specify -Overwrite to overwrite." -Verbose
                throw
            }
        }
        $json = ($InputObject | ConvertTo-Json -Compress)
        Set-Secret -Name $Name -Secret $json -Vault $VaultName -ErrorAction Stop
        Write-AuditLog -Message "Secret '$Name' saved to vault '$VaultName'."
        Write-AuditLog -EndFunction
        return $Name
    }
    catch {
        throw
    }
}
$WarningPreference = 'Continue'
