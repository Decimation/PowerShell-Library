
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

	ffmpeg -i "https://cozycdn.foxtrotstream.xyz/replays/$name/$date/index.m3u8" -c copy -bsf:a aac_adtstoasc -movflags +faststart $outFile
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



function DateAdd {
	param (
		[Parameter(Mandatory = $true)][datetime]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)
	return $a + $b
}

function DateSub {
	param (
		[Parameter(Mandatory = $true)][datetime]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)
	return $a - $b
}

function TimeAdd {
	param (
		[Parameter(Mandatory = $true)][timespan]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)

	return $a + $b
}

function TimeSub {
	param (
		[Parameter(Mandatory = $true)][timespan]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)

	return $a - $b
}

function TimeAbs {
	param (
		[Parameter(Mandatory = $true)][timespan]$c
	)
	return [timespan]::FromTicks([System.Math]::Abs($c.Ticks))
}


function Get-TimeDuration {
	param (
		[Parameter(Mandatory = $true)][timespan]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)

	$a = [timespan]::Parse($a)
	$b = [timespan]::Parse($b)
	$c = (TimeSub $a $b)
	$c = [timespan]::FromTicks([System.Math]::Abs($c.Ticks))

	return $c;
}

function Get-TimeDurationString {
	param(
		[Parameter(Mandatory = $true)][timespan]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)

	return (Get-TimeDuration $a $b).ToString('hh\:mm\:ss')
}



$script:SEPARATOR = $([string]::new('-', $Host.UI.RawUI.WindowSize.Width))

$private:ANSI_UNDERLINE = "$([char]0x1b)[4m"
$private:ANSI_END = "$([char]0x001b)[0m"

function Get-Underline {
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[string]$s
	)
	process {
		#$s
		return "$($ANSI_UNDERLINE)$s$($ANSI_END)"
	}

}

function Get-CenteredString {
	param ($Message)
	return ('{0}{1}' -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($Message.Length / 2)))), $Message)
}