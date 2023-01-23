<#
.SYNOPSIS
    Create ConfigMgr device collections for each make.

.DESCRIPTION
    This script creates Configuration Manager device collections for each device make based on your hardware inventory data.

.EXAMPLE
    .\CreateDeviceCollectionsForEachMake.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

function Get-ExecutionResult {
    # Check if the last command was successfull
    if ($?) {
        Write-Host -ForegroundColor Green "Success"
    }
    else {
        Write-Host -ForegroundColor Red "Error"
    }
}

# Site configuration    
$siteCode = "Your 3-digit site code here" # Site code
$providerMachineName = "FQDN to your ConfigMgr Server here" # SMS Provider machine name
 
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
Set-Location "$($siteCode):\" @initParams
 
##################################### Main #####################################
 
# Get all computer manufacturer from hardware inventory
$Manufacturers = Get-CimInstance `
    -ComputerName $providerMachineName `
    -Namespace "ROOT\SMS\site_$($siteCode)" `
    -Query "SELECT DISTINCT Manufacturer FROM SMS_G_System_COMPUTER_SYSTEM" `
| Select-Object -ExpandProperty Manufacturer
 
# Define CM collection membership query
$Query =
@"
SELECT
    * 
FROM 
    SMS_R_System
INNER JOIN SMS_G_System_COMPUTER_SYSTEM
    on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId
WHERE
    SMS_G_System_COMPUTER_SYSTEM.Manufacturer = '{0}'
"@
 
# Define CM collection evaluation schedule
$cmSchedule = New-CMSchedule -DurationInterval Days -DurationCount 0 -RecurInterval Days -RecurCount 1
 
# Loop through each manufacturer
foreach ($Make in $Manufacturers) {
    Write-Host "Creating CM query for make $Make"
 
    # Create CM query
    New-CMQuery `
        -Name "All `'$Make`' devices" `
        -Comment "All devices with make `'$Make`'" `
        -Expression ($Query -f $Make) `
        -TargetClassName "SMS_R_System" `
    | Out-Null
    Get-ExecutionResult
    
    Write-Host "Creating CM device collection for make $Make"

    # Create CM device collection
    New-CMDeviceCollection `
        -LimitingCollectionName "All Desktop Clients" `
        -Name "All `'$Make`' devices" `
        -RefreshSchedule $cmSchedule `
    | Out-Null
    Get-ExecutionResult
 
    Write-Host "Adding query membership rule for collection `"All `'$Make`' devices`""

    # Get CM device collection membership rules
    $membershipQueryExists = Get-CMDeviceCollectionQueryMembershipRule -CollectionName "All `'$Make`' devices"
 
    if (-not $membershipQueryExists) {
        # Add query to CM device collection membership
        Add-CMDeviceCollectionQueryMembershipRule `
            -CollectionName "All `'$Make`' devices" `
            -QueryExpression ($Query -f $Make) `
            -RuleName "Make = `'$Make`'" `
        | Out-Null
        Get-ExecutionResult
    }
}
