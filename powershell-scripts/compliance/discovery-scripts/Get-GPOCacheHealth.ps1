<#
.SYNOPSIS
    Discover GPO cache health.

.DESCRIPTION
    This script is intended to be used as a ConfigMgr discovery script.
    It checks for corrupt machine and user registry POL files on your computer and reports on health status of named files for use with ConfigMgr Configuration Items.

.EXAMPLE
    .\Get-GPOCacheHealth.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes:    20.09.2021 < Script created >
                     21.09.2021 < Added more logging and changed time difference after which a file will be flagged as outdated >
                     30.09.2021 < Added try/catch for exceptions resulting from unknown user SIDs >
#>

$ErrorActionPreference = "SilentlyContinue"

# Set logging environment
$logPath = "Path\To\Your\ConfigMgr\LogFile\Directory\$($env:COMPUTERNAME)_Discover_RegPOL_Health.log"
$logContent = @("$(Get-Date -Format ('dd.MM.yyyy - HH:mm:ss')) - GPO cache file health check started..")

# Number of past days to check event viewer
$Days = 30

# Define path to machine and user registry POL files
$pathToMachineRegistryPOLFile = "$env:Windir\System32\GroupPolicy\Machine\Registry.pol"
$pathToUserRegistryPOLFile = "$env:Windir\System32\GroupPolicy\User\Registry.pol"

# Default: Files are OK
$machinePOLFileOK = $true
$userPOLFileOK = $true
$machinePOLFileCurrent = $true

# Check the policy files for corruption
try {
   # Check for machine registry POL file health
   if (Test-Path -Path $pathToMachineRegistryPOLFile) {
      $machinePOLFileContent = (Get-Content -Encoding Byte -Path $pathToMachineRegistryPOLFile -TotalCount 4) -join ""
      
      # "8082101103" equals "PReg"
      if ($machinePOLFileContent -ne "8082101103") {
         $logContent += "Machine registry POL file content not starting with expected characters, will flag as unhealthy."
         $machinePOLFileOK = $false
      }
      elseif ($machinePOLFileContent -eq "8082101103") {
         $logContent += "Machine registry POL file content starts with expected characters, will flag as healthy."
      }
   }
   else {
      # Registry POL file does not exists, will GPUpdate at the end of the script to create one
      $logContent += "Machine registry POL file does not exist, marking as unhealthy to force GPUpdate from remediation script."
      $machinePOLFileOK = $false
   }

   # Check for user registry POL file health
   if (Test-Path -Path $pathToUserRegistryPOLFile) {
      $userPOLFileContent = (Get-Content -Encoding Byte -Path $pathToUserRegistryPOLFile -TotalCount 4) -join ""
      
      # "8082101103" equals "PReg"
      if ($userPOLFileContent -ne "8082101103") {
         $logContent += "User registry POL file content not starting with expected characters, will flag as unhealthy."
         $userPOLFileOK = $false
      }
      elseif ($userPOLFileContent -eq "8082101103") {
         $logContent += "User registry POL file content starts with expected characters, will flag as healthy."
      }
   }
   else {
      # Registry POL file does not exist but no need for action
      $logContent += "User registry POL file does not exist but no need for action."
   }

   # Get all user logons in last n days
   $Result = @()   
   $eventLogs = Get-EventLog System -Source Microsoft-Windows-WinLogon -After (Get-Date).AddDays(-$Days) -ErrorAction Stop
   $logContent += "Gathering EventLog entries for Winlogon.."
   $logContent += "Will check Event Log entries for last $Days days."

   if ($eventLogs) {
      $logContent += "Successfully queried EventLog for Winlogon events."
      ForEach ($Log in $eventLogs) {
         if ($Log.InstanceId -eq 7001) {
            $ET = "Logon"
         }
         else {
            Continue
         }
         # Since there have been some errors due to unknown user SIDs which is unproblematic, ignore these errors
         try {
            $Result += New-Object PSObject -Property @{
               Time      = $Log.TimeWritten
               EventType = $ET
               User      = (New-Object System.Security.Principal.SecurityIdentifier $Log.ReplacementStrings[1]).Translate([System.Security.Principal.NTAccount])
            }
         }
         catch [System.Management.Automation.MethodInvocationException] {
            $Result += New-Object PSObject -Property @{
               Time      = $Log.TimeWritten
               EventType = $ET
               User      = "Unknown User"
            } 
         }
         catch {
            $Result += New-Object PSObject -Property @{
               Time      = Get-Date
               EventType = "Unkown EventType"
               User      = "Unknown User"
            }
         }
      }
      # Check if last write time of machine registry POl file is the same as last user logon
      $lastWinLogon = $Result | Where-Object { $_.'EventType' -eq "Logon" } | Sort-Object -Descending -Property Time | Select-Object -First 1
      $lastPOLFileWriteTime = Get-Item -Path $pathToMachineRegistryPOLFile | Select-Object -Property LastWriteTime

      $logContent += "Last Winlogon event on: $($lastWinLogon.Time)."
      $logContent += "Last WriteTime of machine registry POL file on: $($lastPOLFileWriteTime.LastWriteTime)."
      $logContent += "Comparing datetime of last Winlogon event and last WriteTime of machine registry POL file.."
      
      if ($lastPOLFileWriteTime.LastWriteTime.Date -lt $lastWinLogon.Time.Date) {
         # Registry POL file is too old, potentionally corrupt
         $logContent += "Machine registry POL file is older than last WinLogon event by $(($lastWinLogon.Time.Date - $lastPOLFileWriteTime.LastWriteTime.Date).Days) days."
         if ($lastPOLFileWriteTime.LastWriteTime.Date -lt $lastWinLogon.Time.Date.AddDays(-$Days)) {
            $logContent += "Will flag as outdated!"
            $machinePOLFileCurrent = $false
         }
         else {
            $logContent += "Will flag as current (upper limit beeing $Days days)!"
         }
      }
      else {
         # Registry POL file is current
         $logContent += "Machine registry POL file is current"
      }
   }
   else {
      $logContent += "Could not fetch EventLog entries for Winlogon events. There seems to be something wrong with this Windows installation!"
   }
}

catch {
   $logContent += "Error: $($_.Exception.Message)"
   Write-Output "Error: $($_.Exception.Message)"
}

# If all existing files are healthy and current 
if ($machinePOLFileOK -and $userPOLFileOK -and $machinePOLFileCurrent) {
   $logContent += "Reached end of GPO cache file health check: File is healthy and current"
   Write-Output $true
}
else {
   $logContent += "Reached end of GPO cache file health check: Found one or more problems, see above log entries for more details."
   Write-Output $false
}

# Logging
$logContent += "-" * 100
$logContent | Out-File -FilePath $logPath -Append -Force
