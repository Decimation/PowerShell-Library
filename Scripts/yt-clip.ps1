param (
	$Url, 
	$Start, 
	$End, 
	$Output,
	[Parameter(Mandatory = $false)]
	$Other, 
	[Parameter(Mandatory = $false)]
	$Other2 = @('-y')
)

if (Test-Path $Output) {
	$yn = Read-Host -Prompt "$Output already exists. Remove? [y/n/x]"
	switch ($yn) {
		'y' {
			Remove-Item $Output
		}
		'n' {
			
		}
		'x' {
			return
		}
	}
}

#todo: same result?
try {

	$Start = [timespan]::ParseExact($Start, "g", [cultureinfo]::CurrentCulture)
	$End = [timespan]::ParseExact($End, "g", [cultureinfo]::CurrentCulture)
}
catch {
	$Start = ([timespan]::Parse($Start))
	$End = ([timespan]::Parse($End)) 
}


$arg1 = @('-g', $Other, '--youtube-skip-dash-manifest', $Url)
$x = yt-dlp @arg1

$video = $x[0]
$audio = $x[1]
$duration = $End - $Start

$ffArgs = @('-ss', $Start, '-i', $video)

if ($audio) {
	$ffArgs += @('-ss', $Start, '-i', $audio)
}

$ffArgs += @('-t', $duration, `
		"-map", "0:v", "-map", "1:a", `
		"-c:v", "libx264", "-c:a", "aac") `
	+ $Other2 + $Output


Write-Host "$Start - $End ($duration)"
Write-Debug "$($ffArgs -join ' ')"

$p = Start-Process -FilePath 'ffmpeg.exe' -RedirectStandardOutput:$true `
	-ArgumentList $ffArgs -NoNewWindow -PassThru

return $p