<#
.SYNOPSIS
    Remove outdated CCM cache files.

.DESCRIPTION
    This script is intended to be used as a ConfigMgr remediation script.
    It checks for outdated Configuration Manager client cache files, removes them and returns the amount of files it failed to remove.

.EXAMPLE
    .\Remove-OutdatedCcmCacheFiles.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "Stop"

# Specify max amount of days for CCM cache files
$maxRetention = 21

# Connect to resource manager com object
$ccmClient = New-Object -ComObject UIResource.UIResourceMgr

# Get CCM client cache directory location
$ccmCacheDir = ($ccmClient.GetCacheInfo().Location)

# List all applications due in the future or currently running
$pendingApps = @($ccmClient.GetAvailableApplications() | Where-Object {
        ($_.StartTime -gt (Get-Date)) -or ($_.IsCurrentlyRunning -eq 1)
    })

# Create list of applications to purge from cache
$purgeApps = @($ccmClient.GetCacheInfo().GetCacheElements() | Where-Object {
        ($_.ContentID -notin $pendingApps.PackageID) `
            -and ((Test-Path -Path $_.Location) -eq $true) `
            -and ($_.LastReferenceTime -lt (Get-Date).AddDays(- $maxRetention))
    })

# Get all cache directories with an active association
$activeDirs = @($ccmClient.GetCacheInfo().GetCacheElements() | ForEach-Object { 
        Write-Output $_.Location
    })

# Build an array of folders in ccmcache that don't have an active association
$miscDirs = @(Get-ChildItem -Path $ccmCacheDir | Where-Object {
        (($_.PsIsContainer -eq $true) -and ($_.FullName -notin $activeDirs)) 
    })

# Track the number of failures encountered
$failures = 0

# Purge apps that are no longer required
foreach ($App in $purgeApps) {
    try {
        $ccmClient.GetCacheInfo().DeleteCacheElementEx($App.CacheElementID, $false)
    }
    catch {
        $failures ++
    }
}

# Purge orphaned data
foreach ($Dir in $MiscDirs) {
    try {
        $Dir | Remove-Item -Recurse -Force
    }
    catch {
        $failures ++
    }
}

# Return number of cleanup failures 
# so that the CI processor knows there are still apps to be deleted
return $failures
