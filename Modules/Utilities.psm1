<#
# General utilities
#>
function Get-Translation {
	param (
		[Parameter(Mandatory=$true)][string]$x,
		[Parameter(Mandatory=$true)][string]$y
	)

	$cmd = "from googletrans import * `n" +`
	"tmp = Translator().translate('$x', dest='$y')`n" +`
	"print('{0} ({1})'.format(tmp.text, tmp.pronunciation))`n"
	

	$out1 = (python -c $cmd)

	$cmd2 = "from translatepy import * `n" +`
	"tmp2 = Translator().translate('$x', '$y')`n" +`
	"print(tmp2)"

	$out2 = (python -c $cmd2)

	Write-Host "[#1] $out1"
	Write-Host "[#2] $out2"
}
