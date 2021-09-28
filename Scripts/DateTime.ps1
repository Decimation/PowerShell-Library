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

	<#if ([timespan]::op_LessThan($c, [timespan]::Zero)) {

	}#>

	$c = [timespan]::FromTicks([System.Math]::Abs($c.Ticks))

	return $c;
}

function Get-TimeDurationString {
	param
	(
		[Parameter(Mandatory = $true)][timespan]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)
	return (Get-TimeDuration $a $b).ToString('hh\:mm\:ss')
}
