#Requires -Module PSKantan

[CmdletBinding()]
param (
	[Parameter(Mandatory = $false)]
	[string]$arg
)

function Restart-Graphics {
	param($Old)
	
	if (!(IsAdmin)) {
		gsudo
		return
	}
	
	
	if ($Old) {
		
		Import-WinModule PnpDevice
		$d = Get-PnpDevice | Where-Object {
			$_.class -like 'Display*'
		}
		
		$d | Disable-PnpDevice -Confirm:$false
		$d | Enable-PnpDevice -Confirm:$false
	}
	else{
		$a=("/enum-devices", "/class","display")
		$d=pnputil @a
		if (-not $d) {
			throw
		}
		$d1 =$($($($d -match 'instance id') -split ':')[1].Trim())
		$a=("/restart-device",$d1)
		pnputil @a
	}
}

# $k = 'HKCU\SOFTWARE\AMD\DVR\'

$k = 'HKCU:\SOFTWARE\AMD\DVR\'
$k1 = 'HotkeysDisabled'

function Get-AmdSettings {
	
	<# $r = (reg.exe query $k /v $k1) 2>&1
	$v = $r[2].Trim().Split('    ')[2]
	$b = [bool][int]$v
	
	return $b #>

	$c = Get-Item $k
	return $c
}

function Set-AmdSettings {
	<# param ($v)
	
	$ai = [int]$v
	$r = (reg.exe add $k /v $k1 /t REG_DWORD /d $ai /f) 2>&1
	$b = ([string]$r[0]).Contains('success')
	
	return $b #>

	param($Name, $Value)

	Set-ItemProperty -Path $k -Name $Name -Value $Value
}

switch ($arg) {
	'toggle-hk' {
		$h = Get-AmdSettings
		$hkd = $h.GetValue($k1)

		Set-AmdSettings -Name $k1 -Value $($hkd ? 0 : 1)
	}
	'restart-gfx' {
		Restart-Graphics
	}
}

<# if ($arg -eq 'toggle-hk') {
	Amd-ToggleHotkeys
}


 #>
#pwsh -command "& %userprofile%\Documents\PowerShell\Scripts\AMD.ps1 toggle-hk"
