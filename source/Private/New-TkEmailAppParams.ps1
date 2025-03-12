function New-TkEmailAppParams {
    param (
        [string]$AppId,
        [string]$Id,
        [string]$AppName,
        [string]$AppRestrictedSendGroup,
        [string]$CertExpires,
        [string]$CertThumbprint,
        [string]$ConsentUrl,
        [string]$DefaultDomain,
        [string]$SendAsUser,
        [string]$SendAsUserEmail,
        [string]$TenantID
    )
    return [TkEmailAppParams]::new(
        $AppId,
        $Id,
        $AppName,
        $AppRestrictedSendGroup,
        $CertExpires,
        $CertThumbprint,
        $ConsentUrl,
        $DefaultDomain,
        $SendAsUser,
        $SendAsUserEmail,
        $TenantID
    )
}