
[CmdletBinding()]
param (
	[Parameter(Mandatory = $false)]
	$replace
)

$s = Get-Clipboard
$l = [string[]]::new($s.Length)


for ($i = 0; $i -lt $s.Length; $i++) {
	$b1 = $s[$i].ToString().Replace('\displaystyle', '').Trim('{').Trim('}').Trim()
	$b1 = $b1.Replace('}{', "`n").Trim()

	
	$b1 = Parse($b1)

	#($rx[-1].Split("`n ")[0].Trim()) -eq ($rx[-1].Split("`n ")[1].Trim())


	<# $b2 = $b1.Split("`n ")
	
	if ($b2[0].Trim() -eq $b2[1].Trim()) {
		#$l[$i] = $b2
		$b1 = $b2
	}
	
	else {
		
	} #>
	$b1 = $b1.Trim().TrimStart([char]32)
	$b2 = $b1.Split("`n ")
	
	if ($b2.Length -eq 2 -and ($b2[0].Trim() -eq $b2[1].Trim())) {
		#$l[$i] = $b2
		$b1 = $b2[0]
	}
	$l[$i] = ($b1)

}

function Parse($b1) {
	

	#$b1 = [regex]::Replace($b1, '\^{\w}', '^C')
	$b1 = $b1.Replace('^{C}', '^C')
	$b1 = $b1.Replace('^{C', '^C')

	$b1 = $b1.Replace('\varnothing', '\emptyset')
	
	$b1 = $b1.Trim().TrimStart([char]32)
	return $b1
}
if ($replace) {
	Set-Clipboard $l
	Write-Host 'Replaced clipboard'
}

$l = $l | Select-Object -Unique
return $l