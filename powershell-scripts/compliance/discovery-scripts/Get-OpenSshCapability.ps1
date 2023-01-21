<#
.SYNOPSIS
    Get Open SSH Server capability.

.DESCRIPTION
    This script is intended to be used as a ConfigMgr discovery script.
    It determines the installation status of Open SSH Server capability and returns a boolean value.

.EXAMPLE
    .\Get-OpenSshCapability.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "SilentlyContinue"

$installState = (Get-WindowsCapability -Online -Name "*OpenSSH.Server*").State
$startType = (Get-Service -Name "*SSHd*" ).StartType

if ($installState -eq "Installed" -and $startType -eq "Automatic") {
    $true
}
else {
    $false
}