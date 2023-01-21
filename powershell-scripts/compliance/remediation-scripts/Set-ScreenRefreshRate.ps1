<#
.SYNOPSIS
    Set screen refresh rate.

.DESCRIPTION
    This script is intended to be used as a ConfigMgr remediation script.
    It changes the screen refresh rate on your primary monitor, returns the new value and exits with 0 (success) or 1 (failure).

.EXAMPLE
    .\Set-ScreenRefreshRate.ps1

.NOTES
    Created By: User 'mhu' on Stackoverflow; added logging and changed for use with ConfigMgr by Fabian Engbers
    Contact: https://stackoverflow.com/users/932282/mhu
    Company: n/a
    Last Changes: 06.01.2023 < Script created (fen)>

.LINK
    https://stackoverflow.com/questions/56424817/change-windows-10-screen-refresh-rate-59-if-60-60-if-59
#>

function Set-ScreenRefreshRate { 
    <# 
    .Synopsis 
        Sets the screen refresh rate of the primary monitor 
    .Description 
        Uses Pinvoke and ChangeDisplaySettings Win32API to make the change 
    .Example 
        Set-ScreenRefreshRate -Frequency 60        
    #> 

    param ( 
        [Parameter(Mandatory = $true)] 
        [int] $Frequency
    ) 

    $pinvokeCode = @"         
        using System; 
        using System.Runtime.InteropServices; 

        namespace Display 
        { 
            [StructLayout(LayoutKind.Sequential)] 
            public struct DEVMODE1 
            { 
                [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
                public string dmDeviceName; 
                public short dmSpecVersion; 
                public short dmDriverVersion; 
                public short dmSize; 
                public short dmDriverExtra; 
                public int dmFields; 

                public short dmOrientation; 
                public short dmPaperSize; 
                public short dmPaperLength; 
                public short dmPaperWidth; 

                public short dmScale; 
                public short dmCopies; 
                public short dmDefaultSource; 
                public short dmPrintQuality; 
                public short dmColor; 
                public short dmDuplex; 
                public short dmYResolution; 
                public short dmTTOption; 
                public short dmCollate; 
                [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
                public string dmFormName; 
                public short dmLogPixels; 
                public short dmBitsPerPel; 
                public int dmPelsWidth; 
                public int dmPelsHeight; 

                public int dmDisplayFlags; 
                public int dmDisplayFrequency; 

                public int dmICMMethod; 
                public int dmICMIntent; 
                public int dmMediaType; 
                public int dmDitherType; 
                public int dmReserved1; 
                public int dmReserved2; 

                public int dmPanningWidth; 
                public int dmPanningHeight; 
            }; 

            class User_32 
            { 
                [DllImport("user32.dll")] 
                public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE1 devMode); 
                [DllImport("user32.dll")] 
                public static extern int ChangeDisplaySettings(ref DEVMODE1 devMode, int flags); 

                public const int ENUM_CURRENT_SETTINGS = -1; 
                public const int CDS_UPDATEREGISTRY = 0x01; 
                public const int CDS_TEST = 0x02; 
                public const int DISP_CHANGE_SUCCESSFUL = 0; 
                public const int DISP_CHANGE_RESTART = 1; 
                public const int DISP_CHANGE_FAILED = -1; 
            } 

            public class PrimaryScreen  
            { 
                static public string ChangeRefreshRate(int frequency) 
                { 
                    DEVMODE1 dm = GetDevMode1(); 

                    if (0 != User_32.EnumDisplaySettings(null, User_32.ENUM_CURRENT_SETTINGS, ref dm)) 
                    { 
                        dm.dmDisplayFrequency = frequency;

                        int iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_TEST); 

                        if (iRet == User_32.DISP_CHANGE_FAILED) 
                        { 
                            return "Unable to process your request. Sorry for this inconvenience."; 
                        } 
                        else 
                        { 
                            iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_UPDATEREGISTRY); 
                            switch (iRet) 
                            { 
                                case User_32.DISP_CHANGE_SUCCESSFUL: 
                                { 
                                    return "Success"; 
                                } 
                                case User_32.DISP_CHANGE_RESTART: 
                                { 
                                    return "You need to reboot for the change to happen.\n If you feel any problems after rebooting your machine\nThen try to change resolution in Safe Mode."; 
                                } 
                                default: 
                                { 
                                    return "Failed to change the resolution"; 
                                } 
                            } 
                        } 
                    } 
                    else 
                    { 
                        return "Failed to change the resolution."; 
                    } 
                } 

                private static DEVMODE1 GetDevMode1() 
                { 
                    DEVMODE1 dm = new DEVMODE1(); 
                    dm.dmDeviceName = new String(new char[32]); 
                    dm.dmFormName = new String(new char[32]); 
                    dm.dmSize = (short)Marshal.SizeOf(dm); 
                    return dm; 
                } 
            } 
        } 
"@ # don't indend this line

    Add-Type $pinvokeCode -ErrorAction SilentlyContinue
    [Display.PrimaryScreen]::ChangeRefreshRate($Frequency) 
}

function Get-ScreenRefreshRate {
    $frequency = Get-WmiObject -Class "Win32_VideoController" | Select-Object -ExpandProperty "CurrentRefreshRate"
    return $frequency
}

# --------------------- Main ---------------------

$ErrorActionPreference = "Stop"
$desiredRefreshRate = 60 # change this integer to your desired screen refresh rate

# Logging info
$logPath = "Path\To\Your\ConfigMgr\LogFile\Directory\Set-ScreenRefreshRate.log"
$logContent += "$(Get-Date) - Starting remediation of screen refresh rate" + [System.Environment]::NewLine

# Uncomment for debugging purposes 
<# 
$logContent += "$(Get-Date) - Gathering PowerShell environment"
if ([System.Environment]::Is64BitProcess) {
    $logContent += "$(Get-Date) - The process started as 64 Bit and is beeing executed under user $(C:\Windows\System32\whoami.exe)" + [System.Environment]::NewLine
} else {
    $logContent += "$(Get-Date) - The process started as 32 Bit and is beeing executed under user $(C:\Windows\System32\whoami.exe)" + [System.Environment]::NewLine
}
#>

$currentRefreshRate = Get-ScreenRefreshRate
$logContent += "$(Get-Date) - Current refresh rate is at $currentRefreshRate Hz" + [System.Environment]::NewLine

if ($currentRefreshRate -ne $desiredRefreshRate) {
    try {
        $logContent += "$(Get-Date) - Trying to set refresh rate to $desiredRefreshRate Hz" + [System.Environment]::NewLine
        $logContent += "$(Get-Date) - Script output: "
        $logContent += (Set-ScreenRefreshRate -Frequency $desiredRefreshRate) + [System.Environment]::NewLine
        $newRefreshRate = Get-ScreenRefreshRate

        if ($newRefreshRate -eq $desiredRefreshRate) {
            $logContent += "$(Get-Date) - Screen refresh rate successfully set to $newRefreshRate Hz" + [System.Environment]::NewLine
        }
        else {
            $logContent += "$(Get-Date) - Remediation failed, screen refresh rate still at $newRefreshRate Hz" + [System.Environment]::NewLine
            $script:errorExitCode = 1
        }
    }
    catch {
        $logContent += "An error occurred: $($_.Exception.Message)" + [System.Environment]::NewLine
        Write-Error -Message "An error occurred: $($_.Exception.Message)" + [System.Environment]::NewLine
        $script:errorExitCode = 1
    }
}

$logContent += "End of script" + [System.Environment]::NewLine
$logContent += "-" * 100 + [System.Environment]::NewLine
$logContent | Out-File -FilePath $logPath -Append -Force

# Exit either with the previously stated error exit code or write the new refresh rate to STDOUT and exit with exit code 0
if ($errorExitCode) {
    Write-Output $newRefreshRate 
    exit $errorExitCode
}
else {
    Write-Output $newRefreshRate 
}