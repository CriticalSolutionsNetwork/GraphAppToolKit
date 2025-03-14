<#
.SYNOPSIS
    Retrieves an existing certificate from the current user's certificate store based on the provided certificate name.
.DESCRIPTION
    The Get-TkExistingCert function searches for a certificate in the current user's "My" certificate store with a subject that matches the provided certificate name.
    If the certificate is found, it logs audit messages and provides instructions for removing the certificate if needed.
    If the certificate is not found, it logs an audit message indicating that the certificate does not exist.
.PARAMETER CertName
    The subject name of the certificate to search for in the current user's certificate store.
.EXAMPLE
    PS C:\> Get-TkExistingCert -CertName "CN=example.com"
    This command searches for a certificate with the subject "CN=example.com" in the current user's certificate store.
.NOTES
    Author: DrIOSx
    Date: 2025-03-12
    Version: 1.0
#>
function Get-TkExistingCert {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CertName
    )
    $ExistingCert = Get-ChildItem -Path Cert:\CurrentUser\My -ErrorAction SilentlyContinue |
    Where-Object { $_.Subject -eq $CertName } -ErrorAction SilentlyContinue
    if ( $ExistingCert) {
        $VerbosePreference = 'Continue'
        Write-AuditLog "Certificate with subject '$CertName' already exists in the certificate store."
        Write-AuditLog 'You can remove the old certificate if no longer needed with the following commands:'
        Write-AuditLog '1. Verify if more than one cert already exists:'
        Write-AuditLog "Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { `$_.Subject -eq '$CertName' }"
        Write-AuditLog '2. If you are comfortable removing the old certificate, and any duplicates, run the following command:'
        Write-AuditLog "Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { `$_.Subject -eq '$CertName' } | Remove-Item"
        Write-AuditLog "If you would like to remove the certificate, confirm the operation when prompted."
        $shouldProcessOperation = 'Remove-Item'
        $shouldProcessTarget = "Certificate with subject '$CertName' with thumbprint $($ExistingCert.Thumbprint)"
        if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessOperation)) {
            Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq $CertName } -ErrorAction Stop | Remove-Item
            Write-AuditLog "Certificate with subject '$CertName' removed."
        }
        else {
            Write-AuditLog "Certificate with subject '$CertName' not removed."
            throw "Certificate with subject '$CertName' was not removed by user."
        }
        $VerbosePreference = 'SilentlyContinue'
    }
    else {
        Write-AuditLog "Certificate with subject '$CertName' does not exist in the certificate store. Continuing..."
    }
}