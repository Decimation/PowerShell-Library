#Requires -Module PSKantan
[CmdletBinding()]
param (
	[Parameter()]
	[string]$arg
)
function Restart-Graphics {
	
	Import-WinModule PnpDevice
	
	if (!(IsAdmin)) {
		gsudo
		return
	}
	
	$d = Get-PnpDevice | where {
		$_.class -like "Display*"
	}
	
	$d | Disable-PnpDevice -Confirm:$false
	
	$d | Enable-PnpDevice -Confirm:$false
}






function Amd-GetHotkeysDisabled {
	
	$r = (reg.exe query HKCU\SOFTWARE\AMD\DVR\ /v HotkeysDisabled) 2>&1
	$v = $r[2].Trim().Split('    ')[2]
	$b = [bool][int]$v
	
	return $b
}

function Amd-SetHotkeysDisabled {
	param ($v)
	
	$ai = [int]$v
	$r = (reg.exe add HKCU\SOFTWARE\AMD\DVR\ /v HotkeysDisabled /t REG_DWORD /d $ai /f) 2>&1
	$b = ([string]$r[0]).Contains('success')
	
	return $b
}

function Amd-ToggleHotkeys {
	$v = Amd-GetHotkeysDisabled
	$nv = (-not $v)
	$r = Amd-SetHotkeysDisabled $nv
	
	return $r ? $nv: $false
}

if ($arg -eq 'togglehk') {
	Amd-ToggleHotkeys
}

#pwsh -command "& %userprofile%\Documents\PowerShell\Scripts\AMD.ps1 togglehk"
