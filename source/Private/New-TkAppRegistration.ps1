<#
    .SYNOPSIS
    Creates a new enterprise app registration in Azure AD.
    .DESCRIPTION
    The New-TkAppRegistration function creates a new enterprise app registration in Azure AD using the provided display name, certificate thumbprint, and other optional parameters such as required resource access list, sign-in audience, certificate store location, and notes.
    .PARAMETER DisplayName
    The display name for the new app registration. This parameter is mandatory.
    .PARAMETER RequiredResourceAccessList
    An array of MicrosoftGraphRequiredResourceAccess objects for multi-resource mode. This parameter is optional.
    .PARAMETER SignInAudience
    The sign-in audience for the app registration. Valid values are 'AzureADMyOrg', 'AzureADMultipleOrgs', and 'AzureADandPersonalMicrosoftAccount'. The default value is 'AzureADMyOrg'.
    .PARAMETER CertThumbprint
    The thumbprint of the certificate used to secure this app. This parameter is mandatory.
    .PARAMETER CertStoreLocation
    The certificate store location (e.g., "Cert:\CurrentUser\My"). The default value is 'Cert:\CurrentUser\My'. This parameter is optional.
    .PARAMETER Notes
    A descriptive note about this app's purpose or usage. This parameter is optional.
    .EXAMPLE
    $AppRegistration = New-TkAppRegistration -DisplayName "MyApp" -CertThumbprint "ABC123" -Notes "This is a sample app."

    This example creates a new app registration with the display name "MyApp" and the specified certificate thumbprint. A note is also provided.
    .NOTES
    This function requires the Microsoft.Graph PowerShell module.
    Required permissions:
    - Application.ReadWrite.All
    - Directory.ReadWrite.All
#>
function New-TkAppRegistration {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([Microsoft.Graph.PowerShell.Models.MicrosoftGraphApplication1])]
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
            $shouldProcessTarget = "'$DisplayName' for sign-in audience '$SignInAudience' with certificate thumbprint $CertThumbprint."
            $shouldProcessOperation = "New-MgApplication"
            if ($PSCmdlet.ShouldProcess($shouldProcessTarget , $shouldProcessOperation )) {
                $MgApplicationParams = @{
                    DisplayName            = $DisplayName
                    Notes                  = $Notes
                    SignInAudience         = $SignInAudience
                    RequiredResourceAccess = $RequiredResourceAccessList
                    AdditionalProperties   = @{}
                    KeyCredentials         = @(
                        @{
                            Type  = 'AsymmetricX509Cert'
                            Usage = 'Verify'
                            Key   = $Cert.RawData
                        }
                    )
                }
                $AppRegistration = New-MgApplication @MgApplicationParams
            }
            # 2) Create the new app registration
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
