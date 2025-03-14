class TkMemPolicyManagerAppParams  {
    [string]$AppId
    [string]$AppName
    [string]$CertThumbprint
    [string]$ObjectId
    [string]$ConsentUrl
    [string]$PermissionSet
    [string]$Permissions
    [string]$TenantId
    # Constructor
    TkMemPolicyManagerAppParams (
        [string]$AppId,
        [string]$AppName,
        [string]$CertThumbprint,
        [string]$ObjectId,
        [string]$ConsentUrl,
        [string]$PermissionSet,
        [string]$Permissions,
        [string]$TenantId
    ) {
        $this.AppId          = $AppId
        $this.AppName        = $AppName
        $this.CertThumbprint = $CertThumbprint
        $this.ObjectId       = $ObjectId
        $this.ConsentUrl     = $ConsentUrl
        $this.PermissionSet  = $PermissionSet
        $this.Permissions    = $Permissions
        $this.TenantId       = $TenantId
    }

    # (Optional) Helper method to split the Permissions string into an array:
    [string[]] GetPermissionsArray() {
        return $this.Permissions -split '\s+'
    }
}
