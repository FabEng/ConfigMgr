<#
.SYNOPSIS
    Get outdated CCM cache files.

.DESCRIPTION
    This script is intended to be used as a ConfigMgr discovery script.
    It checks for outdated Configuration Manager client cache files and outputs the amount of found items.

.EXAMPLE
    .\Get-OutdatedCcmCacheFiles.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "SilentlyContinue"

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

# Add old app & misc directories
$purgeCount = $purgeApps.Count + $miscDirs.Count

# Return number of applications to purge
return $purgeCount