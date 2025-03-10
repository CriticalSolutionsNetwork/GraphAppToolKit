class TkM365AuditAppParams {
    [string]$AppName
    [string]$AppId
    [string]$ObjectId
    [string]$TenantId
    [string]$CertThumbprint
    [string]$CertExpires
    [string]$ConsentUrl
    [string]$MgGraphPermissions
    [string]$SharePointPermissions
    [string]$ExchangePermissions
    # Constructor
    TkM365AuditAppParams(
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
    ) {
        $this.AppName               = $AppName
        $this.AppId                 = $AppId
        $this.ObjectId              = $ObjectId
        $this.TenantId              = $TenantId
        $this.CertThumbprint        = $CertThumbprint
        $this.CertExpires           = $CertExpires
        $this.ConsentUrl            = $ConsentUrl
        $this.MgGraphPermissions    = $MgGraphPermissions
        $this.SharePointPermissions = $SharePointPermissions
        $this.ExchangePermissions   = $ExchangePermissions
    }
    [DateTime] GetCertExpiresAsDateTime() {
        return [DateTime]::Parse($this.CertExpires)
    }
    # (Optional) Helper methods to split space-delimited permissions into arrays:
    [string[]]GetMgGraphPermissionsArray() {
        return $this.MgGraphPermissions -split '\s+'
    }
    [string[]]GetSharePointPermissionsArray() {
        return $this.SharePointPermissions -split '\s+'
    }
    [string[]]GetExchangePermissionsArray() {
        return $this.ExchangePermissions -split '\s+'
    }
}