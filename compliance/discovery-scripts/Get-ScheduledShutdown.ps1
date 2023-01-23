<#
.SYNOPSIS
    Get scheduled shutdown.

.DESCRIPTION
    This script is intended to be used as a ConfigMgr discovery script.
    It checks for a scheduled shutdown task and returns a boolean value.

.EXAMPLE
    .\Get-ScheduledShutdown.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "Stop"

$shutdownTime = "21:00:00"
$Result = $false
try {
    $schTask = Get-ScheduledTask -TaskName "Shutdown" -ErrorAction SilentlyContinue
    if ($schTask) {
        $schTaskTrigger = $schTask.Triggers
        $schTaskTriggerStart = $schTaskTrigger.StartBoundary

        # String formatting to get the time of day
        $schTaskTriggerStart = ($schTaskTriggerStart.Split("T"))[1]
        $schTaskTriggerStart = ($schTaskTriggerStart.Split("+"))[0]

        if ($schTaskTriggerStart -eq $shutdownTime) {
            $Result = $true
        }
    }

    # Report back to CI
    return $Result
}
catch {
    # Error during script execution
    return $_.Exception.Message
}

