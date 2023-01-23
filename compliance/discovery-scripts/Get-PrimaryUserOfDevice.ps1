<#
.SYNOPSIS
    Get primary user of device.

.DESCRIPTION
    This script is intended to be used as a ConfigMgr discovery script.
    It gathers the last logged on/off users of this computer in the past 30 days and outputs the user with most entries.

.EXAMPLE
    .\Get-PrimaryUserOfDevice.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 17.08.2020 < Script created >
#>

$ErrorActionPreference = "SilentlyContinue"

$Days = 30
$Result = @()
try {
    $eventLogs = Get-EventLog System -Source Microsoft-Windows-WinLogon -After (Get-Date).AddDays(-$Days) -ErrorAction Stop

    if ($eventLogs) {
        ForEach ($Log in $eventLogs) {
            if ($Log.InstanceId -eq 7001) {
                $ET = "Logon"
            }
            elseif ($Log.InstanceId -eq 7002) {
                $ET = "Logoff"
            }
            else {
                Continue
            }
            $Result += New-Object PSObject -Property @{
                Time         = $Log.TimeWritten
                'Event Type' = $ET
                User         = (New-Object System.Security.Principal.SecurityIdentifier $Log.ReplacementStrings[1]).Translate([System.Security.Principal.NTAccount])
            }
        }

        # User that logged on/off the most
        $Script:primaryUser = @($Result | Group-Object -NoElement -Property "User" | Sort-Object -Property "Count" -Descending | Select-Object -ExpandProperty "Name")[0]
    }
    else {
        $Script:primaryUser = ""
    }
}
catch {
    Write-Error $_.Exception.Message
    $Script:primaryUser = ""
}

return $primaryUser
