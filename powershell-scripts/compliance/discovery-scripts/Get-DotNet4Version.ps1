<#
.SYNOPSIS
    Get .NET 4 Version.

.DESCRIPTION
    This script is intended to be used as a ConfigMgr discovery script.
    It ouputs the installed .NET 4 version or an error if no version can be found.

.EXAMPLE
    .\Get-DotNet4Version.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "Stop"

try {
    Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -Name "Version"
}
catch {
    # Error while detection version 
    # Possible reasons: the .Net 4 regkey does not exist
    Write-Error "Error while getting registry key value"
}
