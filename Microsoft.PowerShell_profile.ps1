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

<#-----------------------------------[Modules]-----------------------------------#>

$DeciModules = @{
	Utilities		=	"$Home\Documents\PowerShell\Modules\Utilities.psm1";
	Android		=	"$Home\Documents\PowerShell\Modules\Android.psm1";
	Development		=	"$Home\Documents\PowerShell\Modules\Development.psm1";
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

function Prompt {
	Write-Host ("PS " + "[$(Get-Date -Format "HH:mm:ss")] " + $(Get-Location) +">") -NoNewLine
	return " "
}


<#
.Description
Assigns a specified value to a ref input variable if the ref input variable is null or does not exist 
#>
function AutoAssign([ref]$name, $val) {
	
	#https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_ref?view=powershell-7.1
	#https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_variables?view=powershell-7.1

	if (!($name) -or !($name.HasValue) -or ($name -eq $null)) {
		$name.Value = $val
	}
}

<#-----------------------------------[Aliases]-----------------------------------#>

Set-Alias -Name wh -Value Write-Host
Set-Alias -Name wd -Value Write-Debug

Set-Alias -Name so -Value Select-Object
Set-Alias -Name ss -Value Select-String


Set-Alias -Name gdl -Value gallery-dl
Set-Alias -Name ytdl -Value youtube-dl
Set-Alias -Name fg -Value ffmpeg
Set-Alias -Name fp -Value ffprobe
Set-Alias -Name mg -Value magick