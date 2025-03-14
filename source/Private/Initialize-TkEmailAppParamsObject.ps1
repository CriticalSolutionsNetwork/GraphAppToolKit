<#
    .SYNOPSIS
    Initializes a TkEmailAppParams object with the provided parameters.
    .DESCRIPTION
    The Initialize-TkEmailAppParamsObject function creates and returns a new instance of the TkEmailAppParams class using the provided parameters. This function ensures that all necessary parameters are provided and initializes the object accordingly.
    .PARAMETER AppId
    The application ID used to identify the email application.
    .PARAMETER Id
    The unique identifier for the email application instance.
    .PARAMETER AppName
    The name of the email application being initialized.
    .PARAMETER AppRestrictedSendGroup
    The group that is restricted from sending emails within the application.
    .PARAMETER CertExpires
    The expiration date of the certificate used by the email application.
    .PARAMETER CertThumbprint
    The thumbprint of the certificate used for authentication.
    .PARAMETER ConsentUrl
    The URL where users can provide consent for the email application.
    .PARAMETER DefaultDomain
    The default domain used by the email application for sending emails.
    .PARAMETER SendAsUser
    The user who will send emails on behalf of the email application.
    .PARAMETER SendAsUserEmail
    The email address of the user who will send emails on behalf of the application.
    .PARAMETER TenantID
    The tenant ID associated with the email application.
    .OUTPUTS
    [TkEmailAppParams]
    Returns a new instance of the TkEmailAppParams class initialized with the provided parameters.
    .EXAMPLE
    $tkEmailAppParams = Initialize-TkEmailAppParamsObject -AppId "12345" -Id "67890" -AppName "MyEmailApp" -AppRestrictedSendGroup "RestrictedGroup" -CertExpires "2023-12-31" -CertThumbprint "ABCDEF123456" -ConsentUrl "https://consent.url" -DefaultDomain "example.com" -SendAsUser "user@example.com" -SendAsUserEmail "user@example.com" -TenantID "tenant123"

    This example initializes a TkEmailAppParams object with the specified parameters.
#>
function Initialize-TkEmailAppParamsObject {
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