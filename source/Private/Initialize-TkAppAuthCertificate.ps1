
<#
    .SYNOPSIS
    Initializes or retrieves an authentication certificate for the TkApp.
    .DESCRIPTION
    The Initialize-TkAppAuthCertificate function either retrieves an existing certificate by thumbprint or creates a new self-signed certificate if no thumbprint is provided. The function logs the process and supports ShouldProcess for confirmation prompts.
    .PARAMETER Thumbprint
    The thumbprint of the certificate to retrieve. If omitted, a new self-signed certificate is created.
    .PARAMETER AppName
    An optional name to store in the output object (e.g., the associated app name).
    .PARAMETER Subject
    The subject name for the new certificate if no thumbprint is provided. Default is 'CN=TkDefaultSelfSignedCert'.
    .PARAMETER CertStoreLocation
    The certificate store location (e.g., "Cert:\CurrentUser\My"). Default is 'Cert:\CurrentUser\My'.
    .PARAMETER KeyExportPolicy
    Exportable key policy for the new certificate. Valid values are 'Exportable' and 'NonExportable'. Default is 'NonExportable'.
    .OUTPUTS
    PSCustomObject
    An object containing the certificate thumbprint and expiration date. If AppName is provided, it is included in the output object.
    .EXAMPLE
    Initialize-TkAppAuthCertificate -Thumbprint 'ABC123DEF456'
    .EXAMPLE
    Initialize-TkAppAuthCertificate -Subject 'CN=MyAppCert' -AppName 'MyApp'
    .NOTES
    This function requires the user to have appropriate permissions to access the certificate store and create certificates.
#>
function Initialize-TkAppAuthCertificate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The thumbprint of the certificate to retrieve. If omitted, a new self-signed certificate is created.'
        )]
        [string]
        $Thumbprint,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'An optional name to store in the output object (e.g., the associated app name).'
        )]
        [string]
        $AppName,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The subject name for the new certificate if no thumbprint is provided.'
        )]
        [string]
        $Subject = 'CN=TkDefaultSelfSignedCert',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The certificate store location (e.g., "Cert:\CurrentUser\My").'
        )]
        [string]
        $CertStoreLocation = 'Cert:\CurrentUser\My',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Exportable key policy for the new certificate.'
        )]
        [ValidateSet('Exportable', 'NonExportable')]
        [string]
        $KeyExportPolicy = 'NonExportable'
    )
    if (-not $script:LogString) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    Write-AuditLog '###############################################'
    try {
        if ($Thumbprint) {
            # Retrieve an existing certificate
            $Cert = Get-ChildItem -Path $CertStoreLocation | Where-Object { $_.Thumbprint -eq $Thumbprint }
            if (-not $Cert) {
                throw "Certificate with thumbprint $Thumbprint not found in $CertStoreLocation."
            }
            Write-AuditLog "Retrieved certificate with thumbprint $Thumbprint from $CertStoreLocation."
        }
        else {
            # Prompt before creating a new certificate
            $shouldProcessTarget = "'Subject:$Subject' in $CertStoreLocation"
            $shouldProcessOperation = 'New-SelfSignedCertificate'
            if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
                Get-TkExistingCert `
                -CertName $Subject `
                -ErrorAction Stop
                $Cert = New-SelfSignedCertificate -Subject $Subject -CertStoreLocation $CertStoreLocation `
                    -KeyExportPolicy $KeyExportPolicy -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256
                Write-AuditLog "Created new self-signed certificate with subject '$Subject' in $CertStoreLocation."
            }
            else {
                Write-AuditLog "Certificate creation was skipped by user confirmation."
                throw 'Certificate creation was skipped by user confirmation.'
            }
        }
        $output = [PSCustomObject]@{
            CertThumbprint = $Cert.Thumbprint
            CertExpires    = $Cert.NotAfter.ToString('yyyy-MM-dd HH:mm:ss')
        }
        if ($AppName) {
            $output | Add-Member -NotePropertyName 'AppName' -NotePropertyValue $AppName
        }
        return $output
    }
    catch {
        throw
    }
    finally {
        Write-AuditLog -EndFunction
    }
}

