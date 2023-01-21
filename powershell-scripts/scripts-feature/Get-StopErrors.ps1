<#
.SYNOPSIS
    Check for system crashes.

.DESCRIPTION
    This scrits is intended to be run as a ConfigMgr script using the scripts function.
    It checks for unexpected shutdowns/stop errors/stopErrorss that have happened during a given timeframe.

.EXAMPLE
    .\Get-StopErrors.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "SilentlyContinue"

$startTime = "" # e.g. "25/07/2022"
$endTime = "" # e. g. "03/08/2022"

$stopErrors = Get-WinEvent -FilterHashtable @{
    logname   = "system"; 
    id        = 1; 
    Level     = 2; 
    StartTime = $startTime; 
    EndTime   = $endTime
}

if ($null -eq $stopErrors) {
    Write-Output "No unexpected shutdowns occured lately."
}
Else {
    Write-Output "Unexpected shutdowns occured in the past few days."
}
