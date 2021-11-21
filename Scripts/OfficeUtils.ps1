. "$ScriptPathRoot\Clipboard.ps1"

function Get-EquationChar {
	param (
		[char]$c
	)

	#Miniscule a: [System.Text.Encoding]::Default.GetString(@(240,157,145,142))
	#Majuscule A: [System.Text.Encoding]::Default.GetString(@(240,157,144,180))
	#Miniscule z: [System.Text.Encoding]::Default.GetString(@(240,157,145,167))
	#Majuscule Z: [System.Text.Encoding]::Default.GetString(@(240,157,145,141))

	$majuscule = [char]::IsUpper($c)
	$miniscule = [char]::IsLower($c)
	$ord = $majuscule ? [int][char]'A' - $c : [int][char]'a' - $c

	$lhs = [char]0
	$b1 = 0
	$b2 = 0
	
	$x = $c -ge [char]'M'

	if ($majuscule) {
		$lhs = 'A'
		$b1 = 144
		$b2 = 180
	}
	elseif ($miniscule) {
		$lhs = 'a'
		$b1 = 145
		$b2 = 142
	}

	if ($x) {
		$b1 = 145
		$b2 = 128
		$ord = [int][char]'M' - $c
	}
	else {
		$ord = [int][char]$lhs - $c
	}

	$ord = [Math]::Abs($ord)

	$b2 += $ord
	$rg1 = @(240, 157, $b1, $b2)

	Write-Verbose "$c`t$ord`t$rg1"

	#for ($c=[int][char]'A'; $c -le [int][char]'Z'; $c++) { Get-EquationChar $c }
	#for ($c=[int][char]'a'; $c -le [int][char]'z'; $c++) { Get-EquationChar $c }

	return [System.Text.Encoding]::Default.GetString($rg1)
}