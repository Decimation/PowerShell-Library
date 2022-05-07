
<#
.DESCRIPTION
Downloads a YouTube clip with yt-dlp and ffmpeg
.LINK
https://gist.github.com/lostfictions/5700848187b8edfb6e45270b462a4534
.EXAMPLE
& "yt-clip.ps1" -Url "https://www.youtube.com/watch?v=SNgNBsCI4EA" -Start '1:10' -End "1:26"
.EXAMPLE
& "yt-clip.ps1" -Url "https://youtu.be/YPqYvll6XD0" -Start '10:52' -End "11:38" -Args2 @('-preset','veryfast')
#>
param (
	# Url
	[alias('u')]
	$Url, 
	# Start time
	[Alias('s')]
	$Start = '0:0:0', 
	# End time
	[alias('e')]
	$End,
	[Parameter(Mandatory = $false)]
	$Output = $null,
	# yt-dlp args
	[Parameter(Mandatory = $false)]
	$Args1,
	# ffmpeg args
	[Parameter(Mandatory = $false)]
	$Args2 = @('-y'),
	[Alias('cf')][switch]$Confirm
)

#$ErrorActionPreference = 'Abort'

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

Write-Host "Start: $Start" -ForegroundColor 'Cyan'
Write-Host "End: $End" -ForegroundColor 'Cyan'

$e_ffmpeg = 'ffmpeg'
$e_ytdlp = 'yt-dlp'

$c_ytdlp = (Get-Command $e_ytdlp)
$c_ffmpeg = (Get-Command $e_ffmpeg)

if (-not $c_ytdlp) {
	Write-Error "$e_ytdlp not found"
	return
}

if (-not $c_ffmpeg) {
	Write-Error "$e_ffmpeg not found"
	return
}

Write-Host "$($c_ytdlp.Path)" -ForegroundColor 'DarkGrey'
Write-Host "$($c_ffmpeg.Path)" -ForegroundColor 'DarkGrey'

# $tf = "hh\.mm\.ss"
$tf = "hh\hmm\mss\s"

$fs = $Start.ToString($tf)
$fe = $End.ToString($tf)

# $arg2 = @($Url, '--print', 'id')
$arg2 = @($Url, '--print', 'title', '--restrict-filenames')

$Output ??= "$(yt-dlp @arg2) ($fs - $fe).mp4"
Write-Host "Output filename: $Output" -ForegroundColor 'Green'

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


function script:Read-Confirmation {
	
	if ($Confirm) {
		switch (Read-Host "Continue? [y/n] (or press enter)") {
			default {
				
			}
			'y' {
				
			}
			'n' {
				exit
			}
		}
	}

}

script:Read-Confirmation

# yt-dlp args

$arg1 = @('-g', $Args1, '--youtube-skip-dash-manifest', $Url)
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
	+ $Args2 + "`"$Output`""


Write-Host "Duration: ($duration)" -ForegroundColor 'DarkGray'
Write-Debug "$($ffArgs -join ' ')"

script:Read-Confirmation

ffmpeg @ffArgs
$of = $(Resolve-Path $Output)

Write-Host "Output: $of" -ForegroundColor 'Green'

<# $p = Start-Process -FilePath 'ffmpeg.exe' -RedirectStandardOutput:$true `
	-ArgumentList $ffArgs -NoNewWindow -PassThru

return $p #>
