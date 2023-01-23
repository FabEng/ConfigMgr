<#
.SYNOPSIS
    Remove Windows Update cache and reboot.

.DESCRIPTION
    This scrits is intended to be run as a ConfigMgr script using the scripts function.
    It stops Windows Updates related services, renames the cache dirs, restarts the services and reboots the computer.
    ATTENTION: Again it reboots the users computer so think twice before running it on a whole collection.

.EXAMPLE
    .\Remove-WUACache.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "Stop"
$dateTime = Get-Date -Format ("dd.MM.yyyy_HH-mm")
$Services = @("BITS", "wuauserv", "CryptSvc", "msiserver")

# Function to wait for service status
function WaitUntilServices($searchString, $status) {
    # Get all services where DisplayName matches $searchString and loop through each of them.
    foreach ($service in (Get-Service -Name $searchString)) {
        # Wait for the service to reach the $status or a maximum of 30 seconds
        $service.WaitForStatus($status, '00:00:30')
    }
}

try {
    # Stop services
    foreach ($service in $Services) {
        Get-Service -Name $service | Stop-Service -Force | Out-Null
        WaitUntilServices -searchString $service -status "Stopped"
    }

    # Rename folders
    if (Test-Path -Path "C:\Windows\SoftwareDistribution") {
        Rename-Item -Force -Path "C:\Windows\SoftwareDistribution" -NewName "SoftwareDistribution_$dateTime.old" | Out-Null
    }
    if (Test-Path -Path "C:\Windows\System32\catroot2") {
        Rename-Item -Force -Path "C:\Windows\System32\catroot2" -NewName "catroot2.old_$dateTime" | Out-Null
    }
       
    # Start services
    foreach ($service in $Services) {
        Get-Service -Name $service | Start-Service | Out-Null
        WaitUntilServices -searchString $service -status "Running"
    }

    Write-Output "Operation successful"

    # Restart computer
    Restart-Computer -Timeout 30 -Force | Out-Null   
}
catch {
    Write-Output "Error: $($_.Exception.Message)"
}
