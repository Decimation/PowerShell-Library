
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

	#ffmpeg -i "https://cozycdn.foxtrotstream.xyz/replays/$name/$date/index.m3u8" -c copy -bsf:a aac_adtstoasc -movflags +faststart $outFile
	
	ffmpeg -i "https://cozycdn.foxtrotstream.xyz/replays/$name/$date/index.m3u8" -c copy -movflags +faststart $outFile
}


function Get-Translation {
	param (
		[Parameter(Mandatory = $true)][string]$x,
		[Parameter(Mandatory = $true)][string]$y
	)

	$cmd = @"
from googletrans import *
tmp = Translator().translate('$x', dest='$y')
print('{0} ({1})'.format(tmp.text, tmp.pronunciation))
print('extra data:')
for x in tmp.extra_data['translation']:
	for y in x:
		if y!=None:
			print(y)
"@
	python -c $cmd
	Write-Host

	$cmd2 = @"
from translatepy import *
tmp2 = Translator().translate('$x', '$y')
print(tmp2)
"@
		
	
	python -c $cmd2
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

function Get-Fraktur {
	param (
		[string]$s
	)
	$x1 = [string]::Empty
	for ($i = 0; $i -lt $s.Length; $i++) {
		$x = $s[$i]
		if (-not [char]::IsLetter($x)) {
			$x1 += $x
			continue
		}
		$upper = [Char]::IsUpper($x)
		#$lower = [Char]::IsLower($x)
		$lhs = $upper ? 0x1d504 :0x1d51e
		$ch = [int][char]($upper ? 'A' : 'a')

		$rhs = [System.Math]::Abs($ch - [int]$x)
		$x1 += U ($lhs + $rhs)
	}

	return $x1
}