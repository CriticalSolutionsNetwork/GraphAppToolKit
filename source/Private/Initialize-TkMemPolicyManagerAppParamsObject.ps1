<#
    .SYNOPSIS
    Initializes a TkMemPolicyManagerAppParams object with the provided parameters.
    .DESCRIPTION
    This function creates and returns a new instance of the TkMemPolicyManagerAppParams class using the provided parameters.
    .PARAMETER AppId
    The unique identifier for the application.
    .PARAMETER AppName
    The name of the application to be initialized.
    .PARAMETER CertThumbprint
    The thumbprint of the certificate used for authentication.
    .PARAMETER ObjectId
    The unique identifier for the object.
    .PARAMETER ConsentUrl
    The URL where consent can be granted for the application.
    .PARAMETER PermissionSet
    The set of permissions required by the application.
    .PARAMETER Permissions
    The specific permissions granted to the application.
    .PARAMETER TenantId
    The unique identifier for the tenant.
    .OUTPUTS
    [TkMemPolicyManagerAppParams] The initialized TkMemPolicyManagerAppParams object.
    .EXAMPLE
    $AppParams = Initialize-TkMemPolicyManagerAppParamsObject -AppId "12345" -AppName "MyApp" -CertThumbprint "ABCDEF" -ObjectId "67890" -ConsentUrl "https://consent.url" -PermissionSet "ReadWrite" -Permissions "All" -TenantId "Tenant123"
#>
function Initialize-TkMemPolicyManagerAppParamsObject {
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