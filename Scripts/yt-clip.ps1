
<#
.DESCRIPTION
Downloads a YouTube clip with yt-dlp and ffmpeg
.LINK
https://gist.github.com/lostfictions/5700848187b8edfb6e45270b462a4534
#>
param (
	$Url, 
	$Start = '0:0:0', 
	$End,
	[Parameter(Mandatory = $false)]
	$Output = $null,
	[Parameter(Mandatory = $false)]
	$Other, 
	[Parameter(Mandatory = $false)]
	$Other2 = @('-y')
)

$arg2 = @($Url, '--print', 'id')
$Output ??= "out_$(yt-dlp @arg2).mp4"
Write-Host "Automatic output filename: $Output"

if (Test-Path $Output) {
	$yn = Read-Host -Prompt "$Output already exists. Remove? [y/n/a]"
	switch ($yn) {
		'y' {
			Remove-Item $Output
		}
		'n' {
			
		}
		'a' {
			return
		}
	}
}


function script:Get-ParsedTime($t) {
	$st = $t.Split(':')

	switch ($st.Length) {
		1 {
			$t = [TimeSpan]::FromSeconds($t)
		}
		2 {
			$t = "0:" + $t
		}
		default {
		}
	}
	
	
	try {
		$t = [timespan]::ParseExact($t, "g", [cultureinfo]::CurrentCulture)	
	}
	catch {
		$t = ([timespan]::Parse($t))
	}

	return $t
}

$Start = script:Get-ParsedTime($Start)
$End = script:Get-ParsedTime($End)

Write-Host "Start: $Start"
Write-Host "End: $End"

$arg1 = @('-g', $Other, '--youtube-skip-dash-manifest', $Url)
$x1 = yt-dlp @arg1

$video = $x1[0]
$audio = $x1[1]
$duration = $End - $Start

$ffArgs = @('-ss', $Start, '-i', $video)

if ($audio) {
	$ffArgs += @('-ss', $Start, '-i', $audio)
}

$ffArgs += @('-t', $duration, `
		"-map", "0:v", "-map", "1:a", `
		"-c:v", "libx264", "-c:a", "aac") `
	+ $Other2 + "`"$Output`""


Write-Host "$Start - $End ($duration)"
Write-Debug "$($ffArgs -join ' ')"

ffmpeg @ffArgs

<# $p = Start-Process -FilePath 'ffmpeg.exe' -RedirectStandardOutput:$true `
	-ArgumentList $ffArgs -NoNewWindow -PassThru

return $p #>
