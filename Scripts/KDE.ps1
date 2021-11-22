function KDE-GetFirstDevice {
	$x = (kdeconnect-cli -l)
	$d1 = $x.Split('`n')[0].Split(':')[1].Trim().Split(' ')[0].Trim()
	return $d1
}

function KDE-Run {
	$d1 = $(KDE-GetFirstDevice)
	return (kdeconnect-cli -d $d1 $args)
}