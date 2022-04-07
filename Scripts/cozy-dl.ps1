<#
.DESCRIPTION 
Downloads replays from cozy.tv
.NOTES
Requires yt-dlp, ffmpeg
.EXAMPLE
cozy-dl 2022-03-09 nick
#>

param (
	# Date of replay (YYYY-MM-DD)
	[Parameter(Mandatory = $true)]
	$Date,
	# Name of streamer
	[Parameter(Mandatory = $true)]
	$Name,
	# Downloader
	[Parameter()]
	$Downloader = 'native'
)

function Get-CozyVod {
	
	$uri = "https://cozycdn.foxtrotstream.xyz/replays/$Name/$Date/index.m3u8"
	Write-Host "Retrieving $uri..." -ForegroundColor Blue

	$wr = Invoke-WebRequest $uri

	if (!($wr)) {
		Write-Error 'Error invoking web request'
		return
	}

	$fx = Get-IndexInfo $wr

	Write-Host "Duration: $($fx.Duration) : $($fx.Segments.Length) segments" -ForegroundColor Green
	Write-Host 'Press any key to start download' -ForegroundColor Yellow

	Read-Host

	yt-dlp.exe -i --prefer-ffmpeg --merge-output-format mp4 --verbose --force-ipv4 --ignore-errors --no-continue `
		--no-overwrites -o "Cozy_$Name`_$Date.mp4" --downloader $Downloader -N 8 `
		--no-check-certificate --force-generic-extractor $uri
}


function script:Get-IndexInfo {
	param (
		$wr
	)
	$segments = $wr.RawContent.Split("`n") | ForEach-Object { 
		$_ | Select-String -Raw -Pattern '_seg.ts' 
	}

	$lastSeg = [int]($segments[-1].Split('_')[0])
	$duration = [timespan]::FromSeconds($lastSeg * 4)
	$info = @{
		'Segments'    = $segments
		'LastSegment' = $lastSeg
		'Duration'    = $duration
	}
	
	return $info
}

Write-Debug "$args"

if (($Name -and $Date)) {
	Get-CozyVod
}
else {
	Write-Error 'Insufficient arguments'
}