. "$ScriptPathRoot\Clipboard.ps1"


function ConvertClipboardTo-Equation {
	$s = Get-ClipboardText $global:UNICODE_FORMAT

	$s2 = [string]::Empty

	for ($i = 0; $i -lt $s.Length; $i++) {
		$s2 += $(ConvertTo-EquationChar $s[$i])
	}

	Set-Clipboard $s2

	Write-Host "$s $UNI_ARROW $s2"

	return $s2
}

function ConvertTo-EquationChar {
	param (

		[Parameter(Mandatory = $true)]
		[char]$c,
		[switch]$copyToClipboard
	)

	#Miniscule a: [System.Text.Encoding]::Default.GetString(@(240,157,145,142))
	#Majuscule A: [System.Text.Encoding]::Default.GetString(@(240,157,144,180))
	#Miniscule z: [System.Text.Encoding]::Default.GetString(@(240,157,145,167))
	#Majuscule Z: [System.Text.Encoding]::Default.GetString(@(240,157,145,141))

	$majuscule = [char]::IsUpper($c)
	$miniscule = [char]::IsLower($c)

	$byte1Maj = 144
	$byte1Min = 145
	$byte2Maj = 180
	$byte2Min = 142
	$byte2MajM = 128

	$majA = [char]'A'
	$minA = [char]'a'
	$majM = [char]'M'

	$ord = $majuscule ? [int]$majA - $c : [int]$minA - $c

	$lhs = [char]0
	$byte1 = 0
	$byte2 = 0

	$x = $c -ge $majM

	if ($c -eq 'h') {
		$rgMinH = @(226, 132, $byte2Min)
		return [System.Text.Encoding]::Default.GetString($rgMinH)
	}

	if ($majuscule) {
		$lhs = $majA
		$byte1 = $byte1Maj
		$byte2 = $byte2Maj
	}
	elseif ($miniscule) {
		$lhs = $minA
		$byte1 = $byte1Min
		$byte2 = $byte2Min
	}

	if ($x -and $majuscule) {
		$byte1 = $byte1Min
		$byte2 = $byte2MajM
		$ord = [int]$majM - $c
	}
	else {
		$ord = [int][char]$lhs - $c
	}

	$ord = [Math]::Abs($ord)
	$byte2 += $ord
	$rg1 = @(240, 157, $byte1, $byte2)

	Write-Verbose "$x | $c`t$ord`t$rg1"

	#for ($c=[int][char]'A'; $c -le [int][char]'Z'; $c++) { ConvertTo-EquationChar $c }
	#for ($c=[int][char]'a'; $c -le [int][char]'z'; $c++) { ConvertTo-EquationChar $c }

	$strVal = [System.Text.Encoding]::Default.GetString($rg1)

	if ($copyToClipboard) {
		Set-Clipboard $strVal
	}

	return $strVal
}

