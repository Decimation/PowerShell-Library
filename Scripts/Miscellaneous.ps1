
<#
.Description
Downloads replay from cozy.tv
#>
function Get-CozyVOD {
	param (
		[Parameter(Mandatory = $true)][string]$url,
		[Parameter(Mandatory = $false)][string]$outFile

	)

	$s = $url.Split('/')
	$name = $s[-3]
	$date = $s[-1]

	if (!($outFile)) {
		$outFile = "$date.mp4"
	}

	ffmpeg.exe -i "https://cozycdn.foxtrotstream.xyz/replays/$name/$date/index.m3u8" -c copy -bsf:a aac_adtstoasc -movflags +faststart $outFile
}