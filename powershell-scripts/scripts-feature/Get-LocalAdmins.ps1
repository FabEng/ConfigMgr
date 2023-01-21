<#
.SYNOPSIS
    Get local admin users.

.DESCRIPTION
    This scrits is intended to be run as a ConfigMgr script using the scripts function.
    It get all users that are members of the local administrators group and outputs them to a CSV file on a central share.
    Make sure the central share is accessible to all devices (check share and NTFS permissions).
    Since this script will run under SYSTEM user context, enable the computer objects to write to the network share.

.EXAMPLE
    .\Get-LocalAdmins.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>

$ErrorActionPreference = "Stop"
$pathToCSVFile = "\\Your\Path\To\A\CSV\File\Local-Admin-Report.csv"

$Result = ""
try {
    # Get local admins and write log to centralized share
    $adminSID = [System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid
    $adminId = New-Object System.Security.Principal.Securityidentifier($adminSID, $null)
    $null, $adminGroup = $adminID.Translate([System.Security.Principal.NtAccount]).value -split "\\"
    
    $localAdmins = Get-LocalGroupMember -Group $adminGroup | `
        ForEach-Object { 
        Write-Output "$env:COMPUTERNAME;$($_.ObjectClass);$($_.Name);$($_.PrincipalSource)" 
    }

    do {
        try {
            Out-File -InputObject $localAdmins -FilePath $pathToCSVFile -Append -Encoding utf8
            $errorVar = $true
        }
        catch {
            $errorVar = $false
        }
    } until ($errorVar -eq $true)

    $Result = "Successfully wrote to log"
}
catch {
    $Result = "Error as User $($env:USERNAME): $($_.Exception.Message)"
}

return $Result
