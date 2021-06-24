function Get-Translation {
	param (
		[Parameter(Mandatory=$true)][string]$x,
		[Parameter(Mandatory=$true)][string]$y
	)

	$cmd = "from googletrans import * `n" +`
	"tmp = Translator().translate('$x', dest='$y')`n" +`
	"print(tmp.text)`n" +`
	"print(tmp.pronunciation)"

	python -c $cmd

	Write-Host

	$cmd2 = "from translatepy import * `n" +`
	"tmp2 = Translator().translate('$x', '$y')`n" +`
	"print(tmp2)"

	python -c $cmd2
}


function Prompt {
	<#$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = [Security.Principal.WindowsPrincipal] $identity
	$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator#>
  
	<#$(if (Test-Path variable:/PSDebugContext) { '[DBG]: ' }
	  elseif($principal.IsInRole($adminRole)) { "[ADMIN]: " }
	  else { '' }
	) + 'PS ' + $(Get-Location) +
	  $(if ($NestedPromptLevel -ge 1) { '>>' }) + '> '#>

	
	Write-Host ("PS " + "[$(Get-Date -Format "HH:mm:ss")] " + $(Get-Location) +">") -NoNewLine
	return " "
}

#Remove-Module -Name Index

Import-Module "$Home\Documents\PowerShell\Modules\Index.psm1"
Import-Module "$Home\Documents\PowerShell\Modules\Android.psm1"

# .
# &