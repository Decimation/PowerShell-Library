
function Amd-GetHotkeysDisabled {

	$r = (reg query HKCU\SOFTWARE\AMD\DVR\ /v HotkeysDisabled) 2>&1

	#$r = ($r | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

	$v = $r[2].Trim().Split('    ')[2]

	$b = [bool][int]$v

	return $b
}


function Amd-SetHotkeysDisabled {
	param (
		$a
	)

	#$ai = [int](-not $a)

	$ai = [int]$a

	$r = (reg add HKCU\SOFTWARE\AMD\DVR\ /v HotkeysDisabled /t REG_DWORD /d $ai /f) 2>&1
	$b = ([string]$r[0]).Contains('success')

	return $b
}

function Amd-ToggleHK {
	$a = Amd-GetHotkeysDisabled
	$nv = (-not $a)
	$r = Amd-SetHotkeysDisabled $nv
	
	if ($r) {
		return $nv
	}
	else {
		return $false
	}
}