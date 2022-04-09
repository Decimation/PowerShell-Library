



function Get-Translation {
	param (
		[Parameter(Mandatory = $true)][string]$x,
		[Parameter(Mandatory = $true)][string]$y,
		[Parameter(Mandatory = $false)][string]$src

	)
	
	if (!($src)) {
		$src = 'auto'
	}

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
import pprint
tmp2 = Translator().translate('$x', '$y',source_language='$src')
print(tmp2)
tmp3 = Translator().transliterate('$x', '$y',source_language='$src')
print(tmp3)
tmp4 = Translator().dictionary('$x', '$y',source_language='$src')
pprint.PrettyPrinter(depth=2).pprint(tmp4.__dict__)
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


<# function tparse {
	param (
		$s
	)

	$a1 = [System.Linq.Enumerable]::TakeWhile($s, [System.Func[char, bool]] { 
			return [char]::IsDigit($args[0]) 
		}) -join ''
	$s = $s[$a1.Length..$s.Length]
	$t = [timespan]::new()
	$b = $true
	for ($i = 0; $i -lt $s.Length; $i++) {
		$c = $s[$i]
		$s2 = $null
		
	}
} #>