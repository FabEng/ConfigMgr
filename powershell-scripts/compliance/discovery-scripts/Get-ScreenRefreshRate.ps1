<#
.SYNOPSIS
    Get screen refresh rate.

.DESCRIPTION
    This script is intended to be used as a ConfigMgr discovery script.
    It gets the screen refresh rate on your primary monitor and returns the Hz value.

.EXAMPLE
    .\Get-ScreenRefreshRate.ps1

.NOTES
    Created By: User 'mhu' on Stackoverflow; added logging and changed for use with ConfigMgr by Fabian Engbers
    Contact: https://stackoverflow.com/users/932282/mhu
    Company: n/a
    Last Changes: 06.01.2023 < Script created (fen)>

.LINK
    https://stackoverflow.com/questions/56424817/change-windows-10-screen-refresh-rate-59-if-60-60-if-59
#>

$ErrorActionPreference = "SilentlyContinue"

# Set logging environment
$logPath = "Path\To\Your\ConfigMgr\LogFile\Directory\Get-ScreenRefreshRate.log"
$logContent += "$(Get-Date) - Starting detection of screen refresh rate" + [System.Environment]::NewLine

$RefreshRate = Get-CimInstance -Class "Win32_VideoController" | Select-Object -ExpandProperty "CurrentRefreshRate"
$logContent += "$(Get-Date) - Current refresh rate is at $RefreshRate Hz" + [System.Environment]::NewLine
$logContent += "End of script" + [System.Environment]::NewLine
$logContent += "-" * 100 + [System.Environment]::NewLine
$logContent | Out-File -FilePath $logPath -Append -Force

# Write the new refresh rate to STDOUT and exit with exit code 0
return $RefreshRate