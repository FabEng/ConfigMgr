<#
.SYNOPSIS
    List all CM apps with/without content dirs and with Deeplinks as deployment type.

.DESCRIPTION
    This script gets all your ConfigMgr apps and checks if the content folder UNC path still exists or if
    it's a Deeplink deployment type.

.EXAMPLE
    .\Get-CMAppsContentDir.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes:   22.01.2023 < Script created >
                    23.01.2023 < Renamed the script >
#>

# Logging
Start-Transcript -Path "Path\To\Your\ConfigMgr\LogFile\Directory\Get-CMAppsContentDir.log" -Append

Write-Host "$(Get-Date) - Trying to connect to the ConfigMgr environment."
try {
    # Site configuration    
    ($siteCode = "Your 3-digit site code here") # Site code
    ($providerMachineName = "FQDN to your ConfigMgr Server here") # SMS Provider machine name
 
    # Customizations
    $initParams = @{}
    #$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
    #$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors
 
    # Import the ConfigurationManager.psd1 module
    if ($null -eq (Get-Module ConfigurationManager)) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
    }
 
    # Connect to the site's drive if it is not already present
    if ($null -eq (Get-PSDrive -Name $siteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name $siteCode -PSProvider CMSite -Root $providerMachineName @initParams
    }
 
    # Set the current location to be the site code.
    $origLocation = Get-Location
    Set-Location "$($siteCode):\" @initParams
}
catch {
    Write-Host "$(Get-Date) - Error connecting to the ConfigMgr env: $($_.Exception.Message)"
    Stop-Transcript
    Exit 1
}

try {
    # Get all ConfigMgr apps
    Write-Host "$(Get-Date) - Getting all CM apps"
    $cmApps = Get-CMApplication
}
catch {
    Write-Host "$(Get-Date) - Couldn't get all CM apps: $($_.Exception.Message)"
    Stop-Transcript
    exit 1
}

# Changing location since paths won't be reachable from ConfigMgr environment
Set-Location $origLocation

# Loop through each application, get full path to deplyoyment type and test if it exists on file system
$cmAppsResult = @()

foreach ($App in $cmApps) {
    # Get deployment type xml
    [xml]$dtXML = $App.SDMPackageXML

    # Get path of deployment type
    $pathtoTest = $dtXML.AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location

    try {
        if ($dtXML.AppMgmtDigest.DeploymentType.Technology -eq "Deeplink") {
            $cmAppsResult += [PSCustomObject]@{
                AppName     = $App.LocalizedDisplayName;
                ContentPath = $pathtoTest;
                PathExists  = "Store App"
            }
            continue
        }

        if (($null -eq $pathtoTest) -or (-not(Test-Path -Path $pathtoTest -ErrorAction Stop))) {
            $cmAppsResult += [PSCustomObject]@{
                AppName     = $App.LocalizedDisplayName;
                ContentPath = $pathtoTest;
                PathExists  = "false"
            }
        }
        else {
            $cmAppsResult += [PSCustomObject]@{
                AppName     = $App.LocalizedDisplayName;
                ContentPath = $pathtoTest;
                PathExists  = "true"
            }
        }
    }
    catch {
        $cmAppsResult += [PSCustomObject]@{
            AppName     = $App.LocalizedDisplayName;
            ContentPath = $pathtoTest;
            PathExists  = "false"
        }
    }
}

# Write results to console and to log through transcript
$cmAppsDirReachable = $cmAppsResult | Where-Object -Property "PathExists" -eq "true"
Write-Host "$(Get-Date) - Apps with existing content dir ($($cmAppsDirReachable.Count)):"
Write-Host ($cmAppsDirReachable | Format-Table | Out-String)

[System.Environment]::NewLine

$cmAppsDeeplink = $cmAppsResult | Where-Object -Property "PathExists" -eq "Store App"
Write-Host "$(Get-Date) - Windows Store Apps ($($cmAppsDeeplink.Count)):"
Write-Host ($cmAppsDeeplink | Format-Table | Out-String)

[System.Environment]::NewLine

$cmAppsDirUneachable = $cmAppsResult | Where-Object -Property "PathExists" -eq "false"
Write-Host "$(Get-Date) - Apps without existing content dir ($($cmAppsDirUneachable.Count)):"
Write-Host ($cmAppsDirUneachable | Format-Table | Out-String)

[System.Environment]::NewLine

Write-Host "$(Get-Date) - Script finished!"
Write-Host ("-" * 100)

Stop-Transcript