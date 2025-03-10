function Set-TkJsonSecret {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,HelpMessage='The name under which to store the secret.'
        )]
        [string]
        $Name,
        [Parameter(
            Mandatory=$true,
            HelpMessage='The object to convert to JSON and store.'
        )]
        [PSObject]
        $InputObject,
        [Parameter(
            Mandatory=$false,
            HelpMessage='Name of the vault. Defaults to GraphEmailAppLocalStore.'
        )]
        [string]
        $VaultName='GraphEmailAppLocalStore',
        [Parameter(
            Mandatory=$false,
            HelpMessage='Name of the vault module to use if auto-registering. Defaults to SecretManagement.JustinGrote.CredMan.'
        )]
        [string]
        $VaultModuleName='SecretManagement.JustinGrote.CredMan',
        [Parameter(
            Mandatory=$false,
            HelpMessage='Overwrite existing secret of the same name without prompting.'
        )]
        [switch]
        $Overwrite
    )
    if(!($script:LogString)){Write-AuditLog -Start}else{Write-AuditLog -BeginFunction}
    try{
        Write-AuditLog "###############################################"
        # Auto-register vault if missing
        if(!(Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue)){
            Write-AuditLog -Message "Registering $VaultName using $VaultModuleName"
            Register-SecretVault -Name $VaultName -ModuleName $VaultModuleName -ErrorAction Stop
            Write-AuditLog -Message "Vault '$VaultName' registered."
        }
        else{
            Write-AuditLog "Vault '$VaultName' is already registered."
        }
        # Check if secret already exists
        $secretExists=(Get-SecretInfo -Name $Name -Vault $VaultName -ErrorAction SilentlyContinue)
        if($secretExists){
            if($Overwrite){
                Write-AuditLog -Message "Overwriting existing secret '$Name' in vault '$VaultName'."
                Remove-Secret -Name $Name -Vault $VaultName -Confirm:$false -ErrorAction Stop
            }
            else{
                Write-AuditLog -Message "Secret '$Name' already exists. Remove it or specify -Overwrite to overwrite." -Severity Warning
                return
            }
        }
        $json=($InputObject | ConvertTo-Json -Compress)
        Set-Secret -Name $Name -Secret $json -Vault $VaultName -ErrorAction Stop
        Write-AuditLog -Message "Secret '$Name' saved to vault '$VaultName'."
        Write-AuditLog -EndFunction
        return $Name
    }
    catch{
        throw
    }
}
