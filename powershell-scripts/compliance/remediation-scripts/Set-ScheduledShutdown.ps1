<#
.SYNOPSIS
    Set scheduled shutdown.

.DESCRIPTION
    This script is intended to be used as a ConfigMgr remediation script.
    It sets a scheduled shutdown task and returns a boolean value.

.EXAMPLE
    .\Set-ScheduledShutdown.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "Stop"

$shutdownTime = "21:00:00"
$shutdownDays = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
$Result = $false
try {
    $schTask = Get-ScheduledTask -TaskName "Shutdown" -ErrorAction SilentlyContinue
    if ($schTask) {
        $schTaskTrigger = $schTask.Triggers
        $schTaskTriggerStart = $schTaskTrigger.StartBoundary

        # String formatting to get the time of day
        $schTaskTriggerStart = ($schTaskTriggerStart.Split("T"))[1]
        $schTaskTriggerStart = ($schTaskTriggerStart.Split("+"))[0]

        if ($schTaskTriggerStart -ne $shutdownTime) {
            # Define task trigger
            $schTaskTrigger = New-ScheduledTaskTrigger -weekly -At $shutdownTime -DaysOfWeek $shutdownDays
            # Set task trigger
            $schTask.Triggers = $schTaskTrigger
            Set-ScheduledTask $schTask | Out-Null
            
            $Result = $true
        }
        else {
            $Result = $true
        }
    }
    else {
        # Scheduled task not registered, therefore register it
        $schTaskAction = New-ScheduledTaskAction  -Execute C:\Windows\System32\shutdown.exe -Argument "-t 0 -f -s"
        $schTaskPrincipal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -RunLevel Highest
        $schTaskTrigger = New-ScheduledTaskTrigger -weekly -At 21:00 -DaysOfWeek @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
        $schTask = New-ScheduledTask -Action $schTaskAction -Principal $schTaskPrincipal -Trigger $schTaskTrigger 

        Register-ScheduledTask -TaskName "Shutdown" -InputObject $schTask -Force | Out-Null
        $Result = $true
    }
    # Report back to CI
    return $Result
}
catch {
    # Error during script execution
    return $_.Exception.Message
}



