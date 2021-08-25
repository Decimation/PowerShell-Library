#region [Fun]
param (
	[Parameter(Mandatory = $true)][string]$x,
	[Parameter(Mandatory = $true)][timespan]$h
)

function watermark([byte[]] $x) {
	$pos = -88
	[array]::Resize([ref]$x, $x.Length + 88)

	[byte[]] $mark = @(32, 68, 117, 114, 97, 116, 105, 111, 110, 32, 101, 100, 105, 116, 
		101, 100, 32, 117, 115, 105, 110, 103, 32, 67, 86, 77, 32, 71, 105, 116, 104, 117, 98, 
		32, 117, 114, 108, 58, 32, 104, 116, 116, 112, 115, 58, 47, 47, 103, 105, 116, 104, 117, 
		98, 46, 99, 111, 109, 47, 119, 114, 101, 102, 103, 116, 122, 119, 101, 118, 101, 47, 67, 
		117, 114, 115, 101, 100, 86, 105, 100, 101, 111, 77, 97, 107, 101, 114)
	
	foreach ($bit in $mark) {
		$pos++
		$x[$x.Length + $pos] = $bit
	}

	return $x
}

function clamp_byte($x) {
	return [System.Math]::Clamp($x, 0, 255)
}

function locate([byte[]]$b) {
	
	$num1 = -1
	
	foreach ($num2 in $b) {
		$num1++
		if ($num2 -eq 109 -and $b[$num1 + 1] -eq 118 -and $b[$num1 + 2] -eq 104 -and $b[$num1 + 3] -eq 100) {
			break

		}
	}
	
	return $num1
}

function Corrupt {
	param (
		[Parameter(Mandatory = $true)][string]$x,
		[Parameter(Mandatory = $true)][timespan]$h
	)
	Import-Module "$Home\Documents\PowerShell\Modules\Utilities.psm1"

	$b = Get-FileBytes $x
	$num1 = locate($b)
	
	if ($h -eq [timespan]::MaxValue) {
		$b[$num1 + 16] = 0
		$b[$num1 + 17] = 0
		$b[$num1 + 18] = 0
		$b[$num1 + 19] = 1
		$b[$num1 + 20] = 127
		$b[$num1 + 21] = [byte]::MaxValue
		$b[$num1 + 22] = [byte]::MaxValue
		$b[$num1 + 23] = [byte]::MaxValue
		Write-Host 'max'
	}
	elseif ($h -eq [timespan]::MinValue) {
		$b[$num1 + 16] = 0;
		$b[$num1 + 17] = 0;
		$b[$num1 + 18] = 0;
		$b[$num1 + 19] = 1;
		$b[$num1 + 20] = [byte]::MaxValue
		$b[$num1 + 21] = [byte]::MaxValue
		$b[$num1 + 22] = [byte]::MaxValue
		$b[$num1 + 23] = 240
		Write-Host 'min'

	}
	else {
		$num2 = [decimal]::ToInt32($h.Hours * 3600 + $h.Minutes * 60 + $h.Seconds) * 1000
		$b[$num1 + 16] = 0
		$b[$num1 + 17] = 0
		$b[$num1 + 18] = 3
		$b[$num1 + 19] = 232
		$b[$num1 + 20] = clamp_byte(($num2 -shr 24))
		$b[$num1 + 21] = clamp_byte(($num2 -shr 16))
		$b[$num1 + 22] = clamp_byte(($num2 -shr 8))
		$b[$num1 + 23] = clamp_byte($num2)
		Write-Host 'custom'
	}
	
	
	$b = watermark($b)
	$x2 = [System.IO.Path]::GetFileNameWithoutExtension($x)
	$n=[System.IO.Path]::Combine($(Get-Location),"$x2-cursed.mp4")
	Write-Host $n
	[System.IO.File]::WriteAllBytes($n, $b)
}

Corrupt -x $x -h $h
#endregion