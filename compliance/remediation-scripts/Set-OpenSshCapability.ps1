<#
.SYNOPSIS
    Add Open SSH server capability.

.DESCRIPTION
    This script is intended to be used as a ConfigMgr remediation script.
    It adds the Open SSH server capability and returns a boolean value.

.EXAMPLE
    .\Set-OpenSshCapability.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "SilentlyContinue"

# Add Open SSH server capability
Get-WindowsCapability -Online -Name "*OpenSSH.server*" | Add-WindowsCapability -Online

Start-Sleep -Seconds 5

# Set the service startup type to 'automatic'
Set-Service -Name "sshd" -StartUpType "Automatic"

# Make sure the service has been installed and the startup type set correctly
$installState = (Get-WindowsCapability -Online -Name "*OpenSSH.Server*").State
$startType = (Get-Service -Name "*SSHd*" ).StartType

if ($installState -eq "Installed" -and $startType -eq "Automatic") {
    $true
}
else {
    $false
}
