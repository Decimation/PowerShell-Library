
#https://gist.github.com/danielmoore/2322634

# region Clipboard

Add-Type -Namespace PowershellPlatformInterop -Name Clipboard -MemberDefinition @'
[DllImport("user32.dll", SetLastError=true)]
public static extern bool EmptyClipboard();

[DllImport("user32.dll", SetLastError=true)]
public static extern IntPtr SetClipboardData(uint uFormat, IntPtr hMem);

[DllImport("user32.dll", SetLastError=true)]
public static extern IntPtr GetClipboardData(uint uFormat);

[DllImport("user32.dll", SetLastError=true)]
public static extern bool OpenClipboard(IntPtr hWndNewOwner);

[DllImport("user32.dll", SetLastError=true)]
public static extern bool CloseClipboard();

[DllImport("user32.dll", SetLastError=true)]
public static extern uint EnumClipboardFormats(uint format);

[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
public static extern int DragQueryFile(IntPtr hDrop, uint iFile, [System.Runtime.InteropServices.Out] System.Text.StringBuilder lpszFile, int cch);
'@

function Assert-Win32CallSuccess {
	param (
		[Switch]$PassThru,
		[Switch]$NullIsError,
		[ScriptBlock]$action
	)
	
	$result = & $action
	
	if ($NullIsError -and $result -eq 0 -or -not $NullIsError -and $result -ne 0) {
		$errorCode = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
		Write-Error "$errorCode"
		[Runtime.InteropServices.Marshal]::ThrowExceptionForHR($errorCode)
	}
	
	if ($PassThru) {
		$result
	}
}
function Open-Clipboard {
	$script:isClipboardOwned = $true
	
	Assert-Win32CallSuccess -NullIsError {
		[PowershellPlatformInterop.Clipboard]::OpenClipboard([IntPtr]::Zero)
	}
	
}

function Close-Clipboard {
	Assert-Win32CallSuccess -NullIsError {
		[PowershellPlatformInterop.Clipboard]::CloseClipboard()
	}
		
	$script:isClipboardOwned = $false
	
}
function Use-Clipboard {
	param ([ScriptBlock]$action, [switch]$keepOpen)
	
	if ($script:isClipboardOwned) {
		return & $action
	}
	
	Open-Clipboard
	
	try {
		& $action
	}
	finally {
		if ($keepOpen -eq $false) {
			
			Close-Clipboard
		}
	}
}

function Clear-Clipboard {
	Use-Clipboard {
		Assert-Win32CallSuccess {
			[PowershellPlatformInterop.Clipboard]::EmptyClipboard()
		}
	}
}


#region Clipboard Formats

$global:CF_ANSI = 1
$global:CF_UNICODE = 13
$global:CF_DRAGQUERY = 15

# endregion

function Set-ClipboardText {
	param (
		[Parameter(ValueFromPipeline = $true)]
		[string]$value
	)
	process {
		
		Use-Clipboard {
			Clear-Clipboard
			
			$ptr = [Runtime.InteropServices.Marshal]::StringToHGlobalUni($value)
			Assert-Win32CallSuccess -NullIsError {
				[PowershellPlatformInterop.Clipboard]::SetClipboardData($CF_UNICODE, $ptr)
			}
			
			$ptr = [Runtime.InteropServices.Marshal]::StringToHGlobalAnsi($value)
			
			Assert-Win32CallSuccess -NullIsError {
				[PowershellPlatformInterop.Clipboard]::SetClipboardData($CF_ANSI, $ptr)
			}
		}
	}
}

function Get-ClipboardFormats {
	Use-Clipboard {
		$prev = 0
		
		while ($true) {
			$prev = Assert-Win32CallSuccess -NullIsError -PassThru {
				[PowershellPlatformInterop.Clipboard]::EnumClipboardFormats($prev)
			}
			
			if ($prev -eq 0) {
				break;
			}
			
			$prev
		}
	}
}

function Get-ClipboardText {
	param (
		[Parameter(Mandatory = $false)]
		$fmt
	)
	
	
	$s = Get-ClipboardData @fmt
	$sz = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($s)
	Close-Clipboard
	return $sz
}

function Get-ClipboardData {
	param (
		[Parameter(Mandatory = $false)]
		$fmt
	)
	
	
	Use-Clipboard {
		if (!($fmt)) {
			$formats = Get-ClipboardFormats
			
			if ($formats -contains $CF_UNICODE) {
				$ptr = Assert-Win32CallSuccess -PassThru -NullIsError {
					[PowershellPlatformInterop.Clipboard]::GetClipboardData($CF_UNICODE)
				}
				
				if ($ptr -ne 0) {
					$ptr
				}
			}
			elseif ($formats -contains $CF_ANSI) {
				$ptr = Assert-Win32CallSuccess -PassThru -NullIsError {
					[PowershellPlatformInterop.Clipboard]::GetClipboardData($CF_ANSI)
				}
				
				if ($ptr -ne 0) {
					return	$ptr
				}
			}
		}
		else {
			$ptr = Assert-Win32CallSuccess -PassThru -NullIsError {
				[PowershellPlatformInterop.Clipboard]::GetClipboardData($fmt)
			}
			
			$s = $ptr
			
			return $s
		}
		
	} -keepOpen
}



function Get-DragQuery {

	<# 
	public static string[] GetDragQueryList()
        {
                var h = Native.GetClipboardData((uint) ClipboardFormat.CF_HDROP);

                var cn = Native.DragQueryFile(h, UInt32.MaxValue, null, 0);
                var rg = new List<string>();

                for (int i = 0; i < cn; i++) {
                        var l    = Native.DragQueryFile(h, (uint) i, null, 0) + 1;
                        var file = new StringBuilder(l);
                        l = Native.DragQueryFile(h, (uint) i, file, l);
                        rg.Add(file.ToString());
                }

                return rg.ToArray();
        }
	#>

	Open-Clipboard

	$ptr = Get-ClipboardData $CF_DRAGQUERY

	if ($ptr -eq 0) {
		Close-Clipboard
		return $null
	}

	$s = [System.Text.StringBuilder]::new(256)
	$i = [PowershellPlatformInterop.Clipboard]::DragQueryFile([System.IntPtr]$ptr, [uint]::MaxValue, $s, 0)

	$rg = @()

	for ($j = 0; $j -lt $i; $j++) {
		$l = [PowershellPlatformInterop.Clipboard]::DragQueryFile([System.IntPtr]$ptr, $j, $null, 0) + 1
		$f = [System.Text.StringBuilder]::new(256)
		$l = [PowershellPlatformInterop.Clipboard]::DragQueryFile([System.IntPtr]$ptr, $j, $f, $l)
		$rg += $f.ToString()
		
	}
	
	Close-Clipboard

	return $rg
}

#endregion


<# Set-Alias -Name gcb -Value Get-Clipboard
Set-Alias -Name gcbt -Value Get-ClipboardText
Set-Alias -Name scb -Value Set-Clipboard
Set-Alias -Name scbt -Value Set-ClipboardText #>

function Get-EnvironmentVariables {
	param (
		[Parameter(Mandatory = $false)]
		[System.EnvironmentVariableTarget]$t
	)
	
	
	if (!($t)) {
		$t = [System.EnvironmentVariableTarget]::Machine
	}
	
	$lm = Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
	$cu = Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment'
	
	if ($t -eq [System.EnvironmentVariableTarget]::Machine) {
		return $lm
	}
	if ($t -eq [System.EnvironmentVariableTarget]::User) {
		return $cu
	}
}

#region Screen

function Set-ScreenRefreshRate { 
	param ( 
		[Parameter(Mandatory = $true)] 
		[int] $Frequency
	) 

	$pinvokeCode = @'
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
'@ # don't indend this line


	Add-Type $pinvokeCode -ErrorAction SilentlyContinue

	[Display.PrimaryScreen]::ChangeRefreshRate($frequency) 
}

function Get-ScreenRefreshRate {
	#$frequency = Get-WmiObject -Class "Win32_VideoController" | Select-Object -ExpandProperty "CurrentRefreshRate"
	$frequency = Get-CimInstance -Class 'Win32_VideoController' 
	| Select-Object -ExpandProperty 'CurrentRefreshRate'

	return $frequency
}
#endregion


# region Windows PWSH

<#$global:WinPSRoot = "$env:WINDIR\System32\WindowsPowerShell\v1.0\"
$global:WinModulePathRoot = "$WinPSRoot\Modules\"
$global:WinModules = gci "$WinModulePathRoot" | % {
	$_.FullName
}#>

<#function __Import-WinModule {
	param ($name)
	Import-Module $name -UseWindowsPowerShell -NoClobber -WarningAction SilentlyContinue
}

#Get-PSSession -Name WinPSCompatSession

function __Get-WinSession {
	return Get-PSSession -Name WinPSCompatSession
}

function __Invoke-WinCommand {
	param ([scriptblock]$x)
	Invoke-Command -Session $(__Get-WinSession) $x
}#>

#Import-WinModule Appx
#Import-WinModule PnpDevice
#Import-WinModule Microsoft.PowerShell.Management

#https://github.com/PowerShell/WindowsCompatibility

#Install-Module WindowsCompatibility -Scope CurrentUser
#Import-Module WindowsCompatability

# endregion

# region Media

$Signature = @'
[DllImport("user32.dll")]
public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);
[DllImport("user32.dll")]
public static extern int PostMessage(int hWnd, int hMsg, int wParam, int lParam);
'@

#Add the SendMessage function as a static method of a class
$global:Win32 = Add-Type -MemberDefinition $Signature -Name 'Win32' -Namespace Win32Functions -PassThru


$WinMedia = "$env:WINDIR\Media"

$script:WinSoundPlayer = ([System.Media.SoundPlayer]::new())


function Start-WinSound {
	param (
		$pred
	)
	
	$p = "$WinMedia\$pred"
	if (-not (Resolve-Path $p -ErrorAction Ignore)) {
		$p = Get-ChildItem "$p.*"
		Write-Debug "$p"
	}
	$script:WinSoundPlayer.SoundLocation = ($p)
	$script:WinSoundPlayer.Play()
}

function Stop-WinSound {
	$script:WinSoundPlayer.Stop()
}

#endregion

function Show-Process($Process, [Switch]$Maximize) {
	$sig = '
    [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);
  '
  
	if ($Maximize) { 
		$Mode = 3 
	}
 else { 
		$Mode = 4 
	}
	$type = Add-Type -MemberDefinition $sig -Name WindowAPI -PassThru
	$hwnd = $process.MainWindowHandle
	$null = $type::ShowWindowAsync($hwnd, $Mode)
	$null = $type::SetForegroundWindow($hwnd) 
}
