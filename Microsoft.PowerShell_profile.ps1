<#
# Profile
#>

<#----------------------------------------------------------------------------#>


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
function Set-Constant {
	
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

	$errPref = $ErrorActionPreference
  
	$ErrorActionPreference = "SilentlyContinue"

	try {
		$fn = Set-Variable -n $name -val $mean -opt Constant -s $surround
		& $fn
	}
	catch {
		Write-Debug "Constant value $name not written"
	}
	finally {
		$ErrorActionPreference = $errPref
	}
	
}

Set-Alias const Set-Constant

<#----------------------------------------------------------------------------#>

$DeciModules = @{
	Index		=	"$Home\Documents\PowerShell\Modules\Index.psm1";
	Android		=	"$Home\Documents\PowerShell\Modules\Android.psm1";
	Win32		=	"$Home\Documents\PowerShell\Modules\Win32.psm1";
	Formatting	=	"$Home\Documents\PowerShell\Modules\Formatting.psm1";
}


<#
.Description
Loads Deci modules
#>
function Import-Deci {
	
	foreach ($x in $DeciModules.Values) {
		Import-Module $x
	}
}



<#
.Description
Unloads Deci modules
#>
function Remove-Deci {
	foreach ($x in $DeciModules.Keys) {
		Remove-Module $x
	}
}



<#
.Description
Reloads Deci modules
#>
function Update-Deci {
	Remove-Deci
	Import-Deci
	
}

Import-Deci

<#----------------------------------------------------------------------------#>



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



function Prompt {
	Write-Host ("PS " + "[$(Get-Date -Format "HH:mm:ss")] " + $(Get-Location) +">") -NoNewLine
	return " "
}


<#
.Description
Assigns a specified value to a ref input variable if the ref input variable is null or does not exist 
#>
function AutoAssign([ref]$name, $val) {
	
	if (!($name) -or !($name.HasValue) -or ($name -eq $null)) {
		$name.Value = $val
	}
}

