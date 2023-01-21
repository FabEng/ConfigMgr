<#
.SYNOPSIS
    Start the Windows Update service.

.DESCRIPTION
    This scrits is intended to be run as a ConfigMgr script using the scripts function.
    It attempts to start the Windows Update service and outputs the result to the script processor.

.EXAMPLE
    .\Start-WUAService.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "Stop"

try {
    Get-Service -Name "Windows Update" | Start-Service
}
catch {
    return "Error while trying to start the service: $($_.Exception.Message)"
}

Start-Sleep -Seconds 10

if ((Get-Service -Name "Windows Update" -ErrorAction SilentlyContinue).Status -eq "Running") {
    # Update service is now running
    return "Service is running"
}
else {
    # Service not running
    return "Service is still not running: $((Get-Service -Name 'Windows Update').Status)"
}
