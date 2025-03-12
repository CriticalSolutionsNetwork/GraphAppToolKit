function New-TkM365AuditAppParams {
    param (
        [string]$AppName,
        [string]$AppId,
        [string]$ObjectId,
        [string]$TenantId,
        [string]$CertThumbprint,
        [string]$CertExpires,
        [string]$ConsentUrl,
        [string]$MgGraphPermissions,
        [string]$SharePointPermissions,
        [string]$ExchangePermissions
    )
    return [TkM365AuditAppParams]::new(
        $AppName,
        $AppId,
        $ObjectId,
        $TenantId,
        $CertThumbprint,
        $CertExpires,
        $ConsentUrl,
        $MgGraphPermissions,
        $SharePointPermissions,
        $ExchangePermissions
    )
}