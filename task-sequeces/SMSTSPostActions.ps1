<#
.SYNOPSIS
    Run actions after the TS completes.

.DESCRIPTION
    This script runs some actions after the ConfigMgr task sequence completes and will be referenced in the TS varable "SMSTSPostAction".
    It forces an update of all the Windows Store apps, since if the language changed during OSD, the store apps need to be updated in order to change to the new localized version.
    It also sets GPUpdate to sync at next reboot and schedules a reboot in 3 mins.

.EXAMPLE
    .\SMSTSPostActions.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 22.01.2023 < Script created >
#>

# ConfigMgr
if (Test-Path -Path "Path\To\Your\ConfigMgr\LogFile\Directory") {
    Start-Transcript -Path "Path\To\Your\ConfigMgr\LogFile\Directory\SMSTSPostActions.log"
}
else {
    Start-Transcript -Path C:\SMSTSPostActions.log
}

try {
    # Force update of Windows Store apps since otherwise those will take time to update
    Write-Host "$(Get-Date) - Getting all installed Windows Store apps.."
    $cimInst = Get-CimInstance -Namespace "root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01"

    Write-Host "$(Get-Date) - Searching for updates for the following apps:"
    $cimInst.AppInventoryResults -split " " | Where-Object { $_ -like "PackageFamilyName*" }
    $cimInst | Invoke-CimMethod -MethodName UpdateScanMethod

    [System.Environment]::NewLine

    # Call GPUpdate to sync at next boot
    Write-Host "$(Get-Date) - Staging GPUpdate.."
    gpupdate.exe /boot

    [System.Environment]::NewLine

    # Allow GPUpdate to take some time to download the policies
    Write-Host "$(Get-Date) - Sleeping 30s to allow GPUpdate to download policies.."
    Start-Sleep -Seconds 30

    [System.Environment]::NewLine

    # Restart the computer
    Write-Host "$(Get-Date) - Initializing reboot in 180s to apply GPOs.."
    shutdown.exe /t 180 /r /c "The computer needs to restart in 3 minutes to finish all Task Sequence actions and will be ready to use afterwards."
}
catch {
    Write-Host "$(Get-Date) - An error occurred: $($_.Execption.Message)"
}
finally {
    Stop-Transcript
}

