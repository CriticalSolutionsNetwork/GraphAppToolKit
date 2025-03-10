<#
    .SYNOPSIS
        Retrieves or creates a self-signed certificate in the specified store.
    .DESCRIPTION
        The Initialize-TkAppAuthCertificate function either retrieves a certificate by thumbprint from
        the specified store or creates a new self-signed certificate if no thumbprint is provided.
        It returns a PSCustomObject containing the certificate's thumbprint, expiration date,
        and an optional AppName (to maintain compatibility with existing usage).
    .PARAMETER Thumbprint
        The thumbprint of the certificate to retrieve. If omitted, a new self-signed certificate
        is created.
    .PARAMETER AppName
        An optional name for the application or usage context of this certificate.
        This is used to populate the "AppName" property in the returned object if needed.
    .PARAMETER Subject
        The certificate subject, for example: "CN=MyNewAppCert". Defaults to "CN=DefaultSelfSignedCert"
        if no thumbprint is provided.
    .PARAMETER CertStoreLocation
        The certificate store path (e.g., "Cert:\CurrentUser\My" or "Cert:\LocalMachine\My").
        Defaults to "Cert:\CurrentUser\My".
    .EXAMPLE
        # Retrieve an existing cert by thumbprint
        Initialize-TkAppAuthCertificate -Thumbprint "9B8B40C5F148B710AD5C0E5CC8D0B71B5A30DB0C"
    .EXAMPLE
        # Create a new self-signed cert for a specific application name
        Initialize-TkAppAuthCertificate -AppName "MyGraphApp" -Subject "CN=MyGraphAppCert"
        Returns an object containing AppName, CertThumbprint, and expiration info.
    .OUTPUTS
        PSCustomObject with:
            - CertThumbprint
            - CertExpires
            - AppName      (if provided)
    .NOTES
        Author: DrIOSx
        Requires: Write-AuditLog
        The user must have permission to create or retrieve certificates from the specified store.
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
            if ($PSCmdlet.ShouldProcess($Subject, "Create new self-signed certificate in $CertStoreLocation")) {
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

