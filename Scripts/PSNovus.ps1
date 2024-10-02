using namespace System.Collections.Generic
using namespace System

function MapSwitchKV {
	[CmdletBinding()]
	param (
		# [Dictionary[String, Object]]
		$BoundParamDict,

		$Map
	)
	
	$boundKeys = $BoundParamDict.Keys
	$boundValues = $BoundParamDict.Values

	$boundKeys | ForEach-Object { $Map[$_] }
}

function Dummy1 {
	param (
		$x,
		[switch]$Sw1
	)
	
	MapSwitchKV $PSBoundParameters @{
		'x'   = 'butt'
		'Sw1' = 'w'
	}
}

function Dummy2 {
	param (
		$x,
		[switch]$Sw1
	)
	
	MapSwitchKV $PSBoundParameters @{
		'x'   = 'butt'
		'Sw1' = 'w'
	}
}