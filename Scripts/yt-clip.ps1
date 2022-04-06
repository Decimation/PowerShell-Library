param (
	$url, $s, $e, $outFile,
	[Parameter(Mandatory = $false)]
	$other
)

function Get-TimeDuration {
	param (
		[Parameter(Mandatory = $true)][timespan]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)

	$a = [timespan]::Parse($a)
	$b = [timespan]::Parse($b)
	$c = ($a - $b)
	$c = [timespan]::FromTicks([System.Math]::Abs($c.Ticks))

	return $c;
}

$a = @('-g', '--youtube-skip-dash-manifest', $url)
$x = yt-dlp @a

$v = $x[0]
$a = $x[1]
$d = Get-TimeDuration ([timespan]::Parse($s)) ([timespan]::Parse($e))

$argb = @('-ss', $s, '-i', $v)


if ($a) {
	$argb += @('-ss', $s, '-i', $a)
}

$argb += @('-t', $d)
$argb += @("-map", "0:v", "-map", "1:a")
$argb += @("-c:v", "libx264", "-c:a", "aac", $outFile)

Write-Host "$d"
Write-Host "$($argb -join ' ')"
Read-Host -Prompt "..."

$p = Start-Process -FilePath 'ffmpeg.exe' -RedirectStandardOutput:$true `
	-ArgumentList $argb -NoNewWindow

