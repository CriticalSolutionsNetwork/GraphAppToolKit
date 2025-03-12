function New-TkMemPolicyManagerAppParams {
    param (
        [string]$AppId,
        [string]$AppName,
        [string]$CertThumbprint,
        [string]$ObjectId,
        [string]$ConsentUrl,
        [string]$PermissionSet,
        [string]$Permissions,
        [string]$TenantId
    )
    return [TkMemPolicyManagerAppParams]::new(
        $AppId,
        $AppName,
        $CertThumbprint,
        $ObjectId,
        $ConsentUrl,
        $PermissionSet,
        $Permissions,
        $TenantId
    )
}