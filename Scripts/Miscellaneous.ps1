
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


function Get-Translation {
	param (
		[Parameter(Mandatory = $true)][string]$x,
		[Parameter(Mandatory = $true)][string]$y
	)

	$cmd = @(
		'from googletrans import *',
		"tmp = Translator().translate('$x', dest='$y')",
		"print('{0} ({1})'.format(tmp.text, tmp.pronunciation))"
		<# "ed = tmp.extra_data['all-translations']"
		"for i in range(len(ed)):"
		"	for j in range(len(ed[i])):"
		"		print(','.join(ed[i][j]))" #>
	)

	#Translator().translate('energy', dest='ja').extra_data['all-translations']

	$f1 = $(Get-TempFile)
	$cmd | Out-File $f1
	python $f1

	$cmd2 = @(
		'from translatepy import *',
		"tmp2 = Translator().translate('$x', '$y')",
		'print(tmp2)'
	)

	$f2 = $(Get-TempFile)
	$cmd2 | Out-File $f2
	python $f2
}
