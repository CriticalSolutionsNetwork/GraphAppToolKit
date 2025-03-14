class TkEmailAppParams {
    [string]$AppId
    [string]$Id
    [string]$AppName
    [string]$CertificateSubject
    [string]$AppRestrictedSendGroup
    [string]$CertExpires
    [string]$CertThumbprint
    [string]$ConsentUrl
    [string]$DefaultDomain
    [string]$SendAsUser
    [string]$SendAsUserEmail
    [string]$TenantID
    # Constructor
    TkEmailAppParams(
        [string]$AppId,
        [string]$Id,
        [string]$AppName,
        [string]$CertificateSubject,
        [string]$AppRestrictedSendGroup,
        [string]$CertExpires,
        [string]$CertThumbprint,
        [string]$ConsentUrl,
        [string]$DefaultDomain,
        [string]$SendAsUser,
        [string]$SendAsUserEmail,
        [string]$TenantID
    ) {
        $this.AppId                  = $AppId
        $this.Id                     = $Id
        $this.AppName                = $AppName
        $this.CertificateSubject     = $CertificateSubject
        $this.AppRestrictedSendGroup = $AppRestrictedSendGroup
        $this.CertExpires            = $CertExpires
        $this.CertThumbprint         = $CertThumbprint
        $this.ConsentUrl             = $ConsentUrl
        $this.DefaultDomain          = $DefaultDomain
        $this.SendAsUser             = $SendAsUser
        $this.SendAsUserEmail        = $SendAsUserEmail
        $this.TenantID               = $TenantID
    }
    # (Optional) A helper method that converts CertExpires to a DateTime object
    [DateTime] GetCertExpiresAsDateTime() {
        return [DateTime]::Parse($this.CertExpires)
    }
}