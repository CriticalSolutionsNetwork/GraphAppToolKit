BeforeAll {
    $script:moduleName = '<% $PLASTER_PARAM_ModuleName %>'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe 'Send-TkEmailAppMessage' {
    Context 'Vault Parameter Set' {
        It 'Should send an email using vault credentials' {
            # Arrange
            $AppName = 'GraphEmailApp'
            $To = 'recipient@example.com'
            $FromAddress = 'sender@example.com'
            $Subject = 'Test Email'
            $EmailBody = 'This is a test email.'
            $VaultName = 'GraphEmailAppLocalStore'

            # Mock dependencies
            Mock -CommandName Get-Secret -MockWith {
                @{
                    AppId = '00000000-1111-2222-3333-444444444444'
                    TenantID = 'contoso.onmicrosoft.com'
                    CertThumbprint = 'AABBCCDDEEFF11223344556677889900'
                } | ConvertTo-Json
            }
            Mock -CommandName Get-ChildItem -MockWith {
                New-Object -TypeName PSCertificate -Property @{
                    Thumbprint = 'AABBCCDDEEFF11223344556677889900'
                    NotAfter = (Get-Date).AddYears(1)
                }
            }
            Mock -CommandName Get-TkMsalToken -MockWith { 'mocked-token' }
            Mock -CommandName Invoke-RestMethod

            # Act
            Send-TkEmailAppMessage -AppName $AppName -To $To -FromAddress $FromAddress -Subject $Subject -EmailBody $EmailBody -VaultName $VaultName

            # Assert
            Assert-MockCalled -CommandName Get-Secret -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Get-ChildItem -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Get-TkMsalToken -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly 1 -Scope It
        }
    }

    Context 'Manual Parameter Set' {
        It 'Should send an email using manually specified credentials' {
            # Arrange
            $AppId = '00000000-1111-2222-3333-444444444444'
            $TenantId = 'contoso.onmicrosoft.com'
            $CertThumbprint = 'AABBCCDDEEFF11223344556677889900'
            $To = 'recipient@example.com'
            $FromAddress = 'sender@example.com'
            $Subject = 'Manual Email'
            $EmailBody = 'Hello from Manual!'

            # Mock dependencies
            Mock -CommandName Get-ChildItem -MockWith {
                New-Object -TypeName PSCertificate -Property @{
                    Thumbprint = 'AABBCCDDEEFF11223344556677889900'
                    NotAfter = (Get-Date).AddYears(1)
                }
            }
            Mock -CommandName Get-TkMsalToken -MockWith { 'mocked-token' }
            Mock -CommandName Invoke-RestMethod

            # Act
            Send-TkEmailAppMessage -AppId $AppId -TenantId $TenantId -CertThumbprint $CertThumbprint -To $To -FromAddress $FromAddress -Subject $Subject -EmailBody $EmailBody

            # Assert
            Assert-MockCalled -CommandName Get-ChildItem -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Get-TkMsalToken -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly 1 -Scope It
        }
    }

    Context 'With Attachments' {
        It 'Should send an email with attachments' {
            # Arrange
            $AppId = '00000000-1111-2222-3333-444444444444'
            $TenantId = 'contoso.onmicrosoft.com'
            $CertThumbprint = 'AABBCCDDEEFF11223344556677889900'
            $To = 'recipient@example.com'
            $FromAddress = 'sender@example.com'
            $Subject = 'Email with Attachments'
            $EmailBody = 'This email has attachments.'
            $AttachmentPath = @('C:\path\to\file1.txt', 'C:\path\to\file2.txt')

            # Mock dependencies
            Mock -CommandName Get-ChildItem -MockWith {
                New-Object -TypeName PSCertificate -Property @{
                    Thumbprint = 'AABBCCDDEEFF11223344556677889900'
                    NotAfter = (Get-Date).AddYears(1)
                }
            }
            Mock -CommandName Get-TkMsalToken -MockWith { 'mocked-token' }
            Mock -CommandName Invoke-RestMethod
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Get-Content -MockWith { 'file content' }

            # Act
            Send-TkEmailAppMessage -AppId $AppId -TenantId $TenantId -CertThumbprint $CertThumbprint -To $To -FromAddress $FromAddress -Subject $Subject -EmailBody $EmailBody -AttachmentPath $AttachmentPath

            # Assert
            Assert-MockCalled -CommandName Get-ChildItem -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Get-TkMsalToken -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Test-Path -Exactly 2 -Scope It
            Assert-MockCalled -CommandName Get-Content -Exactly 2 -Scope It
        }
    }
}

