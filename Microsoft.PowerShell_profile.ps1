function Get-Translation {
	param (
		[Parameter(Mandatory=$true)][string]$x,
		[Parameter(Mandatory=$true)][string]$y
	)

	$cmd = "from googletrans import * `n" +`
	"tmp = Translator().translate('$x', dest='$y')`n" +`
	"print('{0} ({1})'.format(tmp.text, tmp.pronunciation))`n"
	<#"x = tmp.extra_data['synonyms']`n" +`
	"x2 = x[0][1][0][0]`n" +`
	"for v in x2:`n" +`
	"    print(v)"#>

	$out1 = (python -c $cmd)

	$cmd2 = "from translatepy import * `n" +`
	"tmp2 = Translator().translate('$x', '$y')`n" +`
	"print(tmp2)"

	$out2 = (python -c $cmd2)

	Write-Host "[#1] $out1"
	Write-Host "[#2] $out2"
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

function Set-Constant {
	<#
	  .SYNOPSIS
		  Creates constants.
	  .DESCRIPTION
		  This function can help you to create constants so easy as it possible.
		  It works as keyword 'const' as such as in C#.
	  .EXAMPLE
		  PS C:\> Set-Constant a = 10
		  PS C:\> $a += 13
  
		  There is a integer constant declaration, so the second line return
		  error.
	  .EXAMPLE
		  PS C:\> const str = "this is a constant string"
  
		  You also can use word 'const' for constant declaration. There is a
		  string constant named '$str' in this example.
	  .LINK
		  Set-Variable
		  About_Functions_Advanced_Parameters
	#>
	[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$true, Position=0)]
	  [string][ValidateNotNullOrEmpty()]$Name,
  
	  [Parameter(Mandatory=$true, Position=1)]
	  [char][ValidateSet("=")]$Link,
  
	  [Parameter(Mandatory=$true, Position=2)]
	  [object][ValidateNotNullOrEmpty()]$Mean,
  
	  [Parameter(Mandatory=$false)]
	  [string]$Surround = "script"
	)
  
	Set-Variable -n $name -val $mean -opt Constant -s $surround
}
  
Set-Alias const Set-Constant

function Import-Deci {
	
	Import-Module "$Home\Documents\PowerShell\Modules\Index.psm1"
	Import-Module "$Home\Documents\PowerShell\Modules\Android.psm1"
	
}

function Remove-Deci {
	Remove-Module Index
	Remove-Module Android
	
}


function Import-Profile {
	. $PROFILE
}

#region [Modules]

#Remove-Module -Name Index

Import-Deci

#endregion

#$WarningPreference = "SilentlyContinue"

# Chain commands	;
# Dot sourcing		.
# Call				&