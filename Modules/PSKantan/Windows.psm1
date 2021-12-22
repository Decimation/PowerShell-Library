
#https://gist.github.com/danielmoore/2322634
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
		[Runtime.InteropServices.Marshal]::ThrowExceptionForHR($errorCode)
	}
	
	if ($PassThru) {
		$result
	}
}

function Use-Clipboard {
	param ([ScriptBlock]$action)
	
	if ($script:isClipboardOwned) {
		return & $action
	}
	
	$script:isClipboardOwned = $true
	
	Assert-Win32CallSuccess {
		[PowershellPlatformInterop.Clipboard]::OpenClipboard([IntPtr]::Zero)
	}
	
	try {
		& $action
	} finally {
		Assert-Win32CallSuccess {
			[PowershellPlatformInterop.Clipboard]::CloseClipboard()
		}
		
		$script:isClipboardOwned = $false
	}
}

function Clear-Clipboard {
	Use-Clipboard {
		Assert-Win32CallSuccess {
			[PowershellPlatformInterop.Clipboard]::EmptyClipboard()
		}
	}
}


$global:ANSI_FORMAT = 1
$global:UNICODE_FORMAT = 13

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
				[PowershellPlatformInterop.Clipboard]::SetClipboardData($UNICODE_FORMAT, $ptr)
			}
			
			$ptr = [Runtime.InteropServices.Marshal]::StringToHGlobalAnsi($value)
			
			Assert-Win32CallSuccess -NullIsError {
				[PowershellPlatformInterop.Clipboard]::SetClipboardData($ANSI_FORMAT, $ptr)
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
	
	
	Use-Clipboard {
		if (!($fmt)) {
			$formats = Get-ClipboardFormats
			
			if ($formats -contains $UNICODE_FORMAT) {
				$ptr = Assert-Win32CallSuccess -PassThru -NullIsError {
					[PowershellPlatformInterop.Clipboard]::GetClipboardData($UNICODE_FORMAT)
				}
				
				if ($ptr -ne 0) {
					[Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
				}
			} elseif ($formats -contains $ANSI_FORMAT) {
				$ptr = Assert-Win32CallSuccess -PassThru -NullIsError {
					[PowershellPlatformInterop.Clipboard]::GetClipboardData($ANSI_FORMAT)
				}
				
				if ($ptr -ne 0) {
					[Runtime.InteropServices.Marshal]::PtrToStringAnsi($ptr)
				}
			}
		} else {
			$ptr = Assert-Win32CallSuccess -PassThru -NullIsError {
				[PowershellPlatformInterop.Clipboard]::GetClipboardData($fmt)
			}
			
			$s = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
			
			return $s
		}
		
	}
}

Set-Alias -Name gcb -Value Get-Clipboard
Set-Alias -Name gcbt -Value Get-ClipboardText
Set-Alias -Name scb -Value Set-Clipboard
Set-Alias -Name scbt -Value Set-ClipboardText

function Get-EnvironmentVariables {
	param (
		[Parameter(Mandatory = $false)]
		[System.EnvironmentVariableTarget]$t
	)
	
	
	if (!($t)) {
		$t = [System.EnvironmentVariableTarget]::Machine
	}
	
	$lm = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
	$cu = Get-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Environment"
	
	if ($t -eq [System.EnvironmentVariableTarget]::Machine) {
		return $lm
	}
	if ($t -eq [System.EnvironmentVariableTarget]::User) {
		return $cu
	}
}


