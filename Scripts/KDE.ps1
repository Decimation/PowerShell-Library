function Use-Kde {

	return kdeconnect-cli.exe @args
	
}

$global:KdeDevice = Kde-GetFirstDevice

function Kde-GetFirstDevice {
	$x = Use-Kde -l
	$d1 = $x.Split('`n')[0].Split(':')[1].Trim().Split(' ')[0].Trim()
	return $d1
}

function Kde-Run {
	return (Use-Kde -d $global:KdeDevice @args)
}

function Kde-Share {
	param (
		$F
	)
	
}