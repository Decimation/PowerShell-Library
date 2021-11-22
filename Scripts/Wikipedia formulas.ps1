
[CmdletBinding()]
param (
	[Parameter(Mandatory = $false)]
	$replace
)

$s = Get-Clipboard

if ($s.GetType() -eq [type]::GetType('System.String')) {
	$s = @($s)
}

$l = [string[]]::new($s.Length)

function Parse($b1) {

	$b1 = $b1.TrimStart('{').TrimEnd('}').Trim()
	$b1 = $b1.Replace('}{', "`n").Trim()

	$b1 = $b1.Replace('\displaystyle', '')
	$b1 = $b1.Replace('\textstyle', '')
	$b1 = $b1.Replace('\log', 'log')
	$b1 = $b1.Replace('\varnothing', '\emptyset')

	# to-do
	$b1 = $b1.Replace('^{C}', '^C')
	$b1 = $b1.Replace('^{C', '^C')

	$b1 = $b1.Replace('^{c}', '^c')
	$b1 = $b1.Replace('^{c', '^c')

	#$b1 = [regex]::Replace('\^{\w}', '\^\w', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

	$b1 = $b1.Trim().TrimStart([char]32)

	return $b1
}

for ($i = 0; $i -lt $s.Length; $i++) {
	$b1 = $s[$i].ToString()

	$b1 = Parse($b1)

	$b2 = $b1.Split("`n ")

	if ($b2.Length -eq 2 -and ($b2[0].Trim() -eq $b2[1].Trim())) {
		$b1 = $b2[0]
	}

	$l[$i] = ($b1)
}

if ($replace) {
	Set-Clipboard $l
	Write-Host 'Replaced clipboard'
}

$l = $l | Select-Object -Unique

return $l