<#
.SYNOPSIS
    Run Admin Service examples.

.DESCRIPTION
    This script is intended to show examples on how to interact with the Configuration Manager Administratin Service as a REST-API.

.EXAMPLE
    .\RunAdminServiceExamples.ps1

.NOTES
    Created By: Fabian Engbers
    Contact: https://github.com/FabEng
    Last Changes: 21.01.2023 < Script created >
#>


# Ignore self-signed certificate checks
function Disable-CertificateValidation {
    Add-Type @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            ServicePointManager.ServerCertificateValidationCallback +=
                delegate
                (
                    Object obj,
                    X509Certificate certificate,
                    X509Chain chain,
                    SslPolicyErrors errors
                )
                {
                    return true;
                };
        }
    }
"@
    [ServerCertificateValidationCallback]::Ignore()   
}

# Get DeviceResourceId of device
function Get-CMDevice {
    param (
        [string]$Name
    )
    $uri = "https://$adminSrvProv/AdminService/v1.0/Device/?`$filter=Name eq `'$($Name)`'"
 
    # Expected response code: [200] reason [OK]
    Invoke-RestMethod -Method "Get" -Uri $uri -UseDefaultCredentials
}

# Get custom properties for a single device
function Get-CMDeviceExtensions {
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceID,
         
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$DeviceName
    )
 
    if (![string]::IsNullOrEmpty($ResourceID)) {
        $uri = "https://$adminSrvProv/AdminService/v1.0/Device($resourceID)/AdminService.GetExtensionData"
    }
 
    if (![string]::IsNullOrEmpty($DeviceName)) {
        $Device = Get-CMDevice -Name $DeviceName
        $uri = "https://$adminSrvProv/AdminService/v1.0/Device($($Device.value.MachineId))/AdminService.GetExtensionData"
    }
 
    # Expected response code: [200] reason [OK]
    Invoke-RestMethod -Method "Get" -Uri $uri -UseDefaultCredentials
}

# Set a list of custom properties (create or update)
function Set-CMDeviceExtensions {
    <#
    .EXAMPLE
        $body = @{
            "ExtensionData" = @{
                TestParam1 = "Test"
                TestParam2 = "Test"
            }
        }
    #>
 
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceID,
         
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$DeviceName,
 
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateScript({ $null -ne $_ })]
        $Body
    )
     
    if (![string]::IsNullOrEmpty($ResourceID)) {
        $uri = "https://$adminSrvProv/AdminService/v1.0/Device($ResourceID)/AdminService.SetExtensionData"
    }
 
    if (![string]::IsNullOrEmpty($DeviceName)) {
        $Device = Get-CMDevice -Name $DeviceName
        $uri = "https://$adminSrvProv/AdminService/v1.0/Device($($Device.value.MachineId))/AdminService.SetExtensionData"
    }
 
    $jsonBody = ConvertTo-Json -InputObject $Body
 
    # Expected response code: [200] reason [OK]
    Invoke-WebRequest -Method "Post" -Uri $uri -UseDefaultCredentials -Body $jsonBody -ContentType "application/json"
}

# Delete one or more dedicated custom properties
function Remove-CMDeviceExtensions {
    <#
    .EXAMPLE
        $body = @{
            "PropertyNames" = @(TestParam)
        }
    #>
 
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceID,
         
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$DeviceName,
 
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateScript({ $null -ne $_ })]
        $Body
    )
     
    if (![string]::IsNullOrEmpty($ResourceID)) {
        $uri = "https://$adminSrvProv/AdminService/v1.0/Device($ResourceID)/AdminService.DeleteCustomProperties"
    }
 
    if (![string]::IsNullOrEmpty($DeviceName)) {
        $Device = Get-CMDevice -Name $DeviceName
        $uri = "https://$adminSrvProv/AdminService/v1.0/Device($($Device.value.MachineId))/AdminService.DeleteCustomProperties"
    }
 
    $jsonBody = ConvertTo-Json -InputObject $Body
     
    # Expected response code: [204] reason [No Content]
    Invoke-WebRequest -Method "Post" -Uri $uri -UseDefaultCredentials -Body $jsonBody -ContentType "application/json"
}

# Delete all custom properties for a single device
function Remove-AllCMDeviceExtensions {
    <#
    .EXAMPLE
        $body = @{
            "PropertyNames" = @(TestParam)
        }
    #>
 
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceID,
         
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$DeviceName
    )
     
    if (![string]::IsNullOrEmpty($ResourceID)) {
        $uri = "https://$adminSrvProv/AdminService/v1.0/Device($ResourceID)/AdminService.DeleteExtensionData"
    }
 
    if (![string]::IsNullOrEmpty($DeviceName)) {
        $Device = Get-CMDevice -Name $DeviceName
        $uri = "https://$adminSrvProv/AdminService/v1.0/Device($($Device.value.MachineId))/AdminService.DeleteExtensionData"
    }
 
    # Expected response code: [204] reason [No Content]
    Invoke-WebRequest -Method "Post" -Uri $uri -UseDefaultCredentials
}

# ---------------------- Main starts here ----------------------
# Uncomment the example you want to test

# Define variable to connect to your ConfigMgr server
$adminSrvProv = "FQDN to your CM server here"
 
<#
# Since there may be authetication errors if certificates are not set up correctly, you may circumvent these by uncommenting the following lines
# Ignore certificate validation
Disable-CertificateValidation
#>

<#
# -------- Example 1
# Get custom properties by ResourceID
$resourceID = "ResourceID of a CM device here"
Get-CMDeviceExtensions -ResourceId $resourceID
#>

<#
# -------- Example 2
# Get custom properties by DeviceName
$deviceName = "DeviceName of a CM device here"
Get-CMDeviceExtensions -DeviceName $deviceName
#>

<#
# -------- Example 3
# Set one or more custom properties
$deviceName = "DeviceName of a CM device here"
$additionalProperties = @{
    "ExtensionData" = @{
        TestParam1 = "Test"
        TestParam2 = "Test"
    }
}
Set-CMDeviceExtensions -DeviceName $deviceName -Body $additionalProperties
#>

<#
# -------- Example 4
# Remove one or more custom properties
$deviceName = "DeviceName of a CM device here"
$removalProperties = @{
    "PropertyNames" = @(
        "TestParam2", 
        "Location"
    )
}
Remove-CMDeviceExtensions -DeviceName $deviceName -Body $removalProperties
#>

<#
# -------- Example 5
# Remove all custom properties
$deviceName = "DeviceName of a CM device here"
Remove-AllCMDeviceExtensions -DeviceName $deviceName
#>
