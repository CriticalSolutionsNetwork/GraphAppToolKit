<#
    .SYNOPSIS
        Creates a new enterprise application registration in Azure AD with a specified certificate.
    .DESCRIPTION
        The New-TkAppRegistration function creates a new Azure AD application registration (sometimes called
        an enterprise app) using Microsoft Graph. It sets the sign-in audience, attaches a certificate for authentication,
        and configures one or more application permission IDs for the specified resource (e.g., Microsoft Graph).
        Logging is handled by the Write-AuditLog function, and the newly created application object is returned.
    .PARAMETER DisplayName
        The display name for the new app registration.
    .PARAMETER CertThumbprint
        The thumbprint of the certificate used to secure this app, located in the CurrentUser certificate store.
    .PARAMETER ResourceAppId
        The Azure AD resource (for example, the Microsoft Graph app ID: 00000003-0000-0000-c000-000000000000).
    .PARAMETER PermissionIds
        One or more permission IDs (application permissions) to grant for the resource. For example, "Mail.Send".
    .PARAMETER SignInAudience
        The sign-in audience for the app registration. Valid values are "AzureADMyOrg", "AzureADMultipleOrgs",
        and "AzureADandPersonalMicrosoftAccount". Defaults to "AzureADMyOrg".
    .EXAMPLE
        PS C:\> New-TkAppRegistration -DisplayName "MyEnterpriseApp" -CertThumbprint "AABBCCDDEEFF1122" -ResourceAppId "00000003-0000-0000-c000-000000000000" -PermissionIds "Mail.Send"
        Creates a new Azure AD application named "MyEnterpriseApp", attaches the specified certificate, targets the Microsoft Graph
        resource (AppId 00000003-0000-0000-c000-000000000000), and grants the "Mail.Send" permission.
    .INPUTS
        None. You cannot pipe input to this function.
    .OUTPUTS
        Microsoft.Graph.PowerShell.Models.MicrosoftGraphApplication
        Returns the newly created Azure AD application registration object.
    .NOTES
        Author: DrIOSx
        Requires: Microsoft.Graph PowerShell module, Write-AuditLog function
        The user must have permissions in Azure AD to create and manage applications.
#>
function New-TkAppRegistration {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = `
                'The display name for the new app registration.'
        )]
        [string]
        $DisplayName,
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'Pass an array of MicrosoftGraphRequiredResourceAccess objects for multi-resource mode.'
        )]
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess[]]
        $RequiredResourceAccessList,
        [Parameter(
            HelpMessage = `
                'The sign-in audience for the app registration.'
        )]
        [ValidateSet('AzureADMyOrg', 'AzureADMultipleOrgs', 'AzureADandPersonalMicrosoftAccount')]
        [string]
        $SignInAudience = 'AzureADMyOrg',
        [Parameter(
            Mandatory = $true,
            HelpMessage = `
                'The thumbprint of the certificate used to secure this app.'
        )]
        [string]
        $CertThumbprint,
        [Parameter(
            Mandatory = $false,
            HelpMessage = `
                'The certificate store location (e.g., "Cert:\CurrentUser\My").'
        )]
        [string]
        $CertStoreLocation = 'Cert:\CurrentUser\My',
        [Parameter(
            Mandatory = $false,
            HelpMessage = "A descriptive note about this app's purpose or usage."
        )]
        [string]
        $Notes
    )
    # Begin Logging
    if (-not $script:LogString) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    Write-AuditLog '###############################################'
    try {
        Write-AuditLog "Creating new enterprise app registration for '$DisplayName'."
        if ($CertThumbprint) {
            # 1) Retrieve the certificate from the CurrentUser store
            $Cert = Get-ChildItem -Path $CertStoreLocation |
            Where-Object { $_.Thumbprint -eq $CertThumbprint }
            if (-not $Cert) {
                throw "Certificate with thumbprint $CertThumbprint not found in $CertStoreLocation."
            }
            # 2) Create the new app registration
            $AppRegistration = New-MgApplication `
                -DisplayName $DisplayName `
                -Notes $Notes `
                -SignInAudience $SignInAudience `
                -RequiredResourceAccess $RequiredResourceAccessList `
                -AdditionalProperties @{} `
                -KeyCredentials @(
                @{
                    Type  = 'AsymmetricX509Cert'
                    Usage = 'Verify'
                    Key   = $Cert.RawData
                }
            )
            if (-not $AppRegistration) {
                throw "The app creation failed for '$DisplayName'."
            }
            Write-AuditLog "App registration created with app Object ID $($AppRegistration.Id)."
            return $AppRegistration
        }
        else {
            throw 'CertThumbprint is required to create an app registration. No other methods are supported yet.'
        }
    }
    catch {
        throw
    }
    finally {
        Write-AuditLog -EndFunction
    }
}
