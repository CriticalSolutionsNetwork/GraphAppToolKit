<#
    .SYNOPSIS
        Initializes a TkM365AuditAppParams object with the provided parameters.
    .DESCRIPTION
        This function initializes a TkM365AuditAppParams object using the parameters provided by the user. It sets up the application name, application ID, object ID, tenant ID, certificate thumbprint, certificate expiration date, consent URL, and various permissions for Microsoft Graph, SharePoint, and Exchange. This allows for the configuration and management of the TkM365AuditAppParams object within the application.
    .PARAMETER AppName
        The name of the application.
    .PARAMETER AppId
        The unique identifier for the application.
    .PARAMETER ObjectId
        The unique identifier for the object.
    .PARAMETER TenantId
        The unique identifier for the tenant.
    .PARAMETER CertThumbprint
        The thumbprint of the certificate used.
    .PARAMETER CertExpires
        The expiration date of the certificate.
    .PARAMETER ConsentUrl
        The URL used for consent.
    .PARAMETER MgGraphPermissions
        An array of permissions for Microsoft Graph.
    .PARAMETER SharePointPermissions
        An array of permissions for SharePoint.
    .PARAMETER ExchangePermissions
        An array of permissions for Exchange.
    .OUTPUTS
        TkM365AuditAppParams
        A new instance of the TkM365AuditAppParams object initialized with the provided parameters.
    .EXAMPLE
        $Params = Initialize-TkM365AuditAppParamsObject -AppName "MyApp" -AppId "12345" -ObjectId "67890" -TenantId "tenant123" -CertThumbprint "ABCDEF" -CertExpires "2023-12-31" -ConsentUrl "https://consent.url" -MgGraphPermissions @("Permission1", "Permission2") -SharePointPermissions @("Permission1") -ExchangePermissions @("Permission1", "Permission2")
#>
function Initialize-TkM365AuditAppParamsObject {
    param (
        [string]$AppName,
        [string]$AppId,
        [string]$ObjectId,
        [string]$TenantId,
        [string]$CertThumbprint,
        [string]$CertExpires,
        [string]$ConsentUrl,
        [string[]]$MgGraphPermissions,
        [string[]]$SharePointPermissions,
        [string[]]$ExchangePermissions
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