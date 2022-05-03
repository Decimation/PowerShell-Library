
$k0 = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\'
$k1 = 'VirtualDesktopAltTabFilter'
$k2 = 'VirtualDesktopTaskbarFilter'


function Set-VTSetting {
	param (
		[switch]$AltTabFilter,
		[switch]$TaskbarFilter
	)

	reg add $k0 /v $k2 /t REG_DWORD /d $($AltTabFilter ? 1 : 0) /f
	reg add $k0 /v $k1 /t REG_DWORD /d $($TaskbarFilter ? 1 : 0) /f
}

function Get-VTSetting {
	$ht = @{
		
	}

	foreach ($k in @($k1, $k2)) {

		$x = reg query $k0 /v $k
		$x2 = (($x.Split('`n') | Where-Object { $_ })[1].Trim() -split ' ')[-1]
		
		$ht.$k = $x2
	}
	return $ht

}