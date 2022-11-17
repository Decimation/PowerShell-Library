$c = [int][System.Environment]::GetEnvironmentVariable("CUR_VOL")
[int]$n = 0
Write-Host "$($c)|$n"
switch ([int]$c) {
	100 {
		$n = 10
		break;
	}
	10 {
		$n = 100
		break;
	}
	Default {}
}
Write-Host "$n"
[System.Environment]::SetEnvironmentVariable("CUR_VOL", $n)
soundvolumeview /setvolume MusicBee $n