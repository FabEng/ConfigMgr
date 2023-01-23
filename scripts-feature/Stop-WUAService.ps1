<#
.SYNOPSIS
    Stop the Windows Update service.

.DESCRIPTION
    This scrits is intended to be run as a ConfigMgr script using the scripts function.
    It attempts to force stop the Windows Update service and outputs the result to the script processor.

.EXAMPLE
    .\Stop-WUAService.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "Stop"

try {
    Get-Service -Name "Windows Update" | Stop-Service -Force
}
catch {
    return "Error while trying to stop the service: $($_.Exception.Message)"
}

Start-Sleep -Seconds 10

if ((Get-Service -Name "Windows Update" -ErrorAction SilentlyContinue).Status -eq "Running") {
    # Update service still running
    Write-Output "Still running: $((Get-Service -Name "Windows Update").Status)"
}
else {
    # Service stopped
    Write-Output "Service stopped"
}
