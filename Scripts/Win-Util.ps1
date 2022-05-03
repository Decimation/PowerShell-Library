#Requires -Module PSKantan

#todo: this is kind of overengineered...

$k0 = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\'
$k1 = 'VirtualDesktopAltTabFilter'
$k2 = 'VirtualDesktopTaskbarFilter'
$kr = @($k1, $k2)


function Set-VTSetting {
	param (
		[parameter(ParameterSetName = 'Toggle')][switch]
		$Toggle,
		
		[parameter(ParameterSetName = 'Direct')][switch]
		$AltTabFilter,
		[parameter(ParameterSetName = 'Direct')][switch]
		$TaskbarFilter
	)
	
	$rv = $null
	$ht = $null
	if ($Toggle) {
		$ht = Get-VTSetting
		foreach ($kk in $kr) {
			# $b = $ht.$kk ? 0 : 1
			# $ht.$kk = $b
			$ht[$kk] = $ht[$kk]?0:1

		}
		
	}
	
	else {
		
		<# $r1 = reg add $k0 /v $k2 /t REG_DWORD /d $($AltTabFilter ? 1 : 0) /f
		$r2 = reg add $k0 /v $k1 /t REG_DWORD /d $($TaskbarFilter ? 1 : 0) /f
		$rv = $r1, $r2 #>
		
		$ht = @{
			$k1 = $AltTabFilter ? 1 : 0
			$k2 = $TaskbarFilter ? 1 : 0
		}

	}
	
	
	foreach ($hkk in $ht.Keys) {
		$rr = reg add $k0 /v $hkk /t REG_DWORD /d $($ht[$hkk]) /f
	}
	
	$rv = $rr
	return $rv, $ht

}

function Get-VTSetting {
	$ht = @{
		
	}

	foreach ($k in @($k1, $k2)) {

		$x = reg query $k0 /v $k
		$x2 = (($x.Split('`n') | Where-Object { $_ })[1].Trim() -split ' ')[-1]
		
		$ht.$k = [int]$x2
	}
	return $ht

}