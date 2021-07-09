<#
# General utilities
#>



#region [Formatting]

$script:uni_arrow = $([char]0x2192)

$private:ANSI_UNDERLINE = "$([char]0x1b)[4m"
$private:ANSI_END = "$([char]0x001b)[0m"

function Get-Underline {
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[string]$s
	)
	
	return "$($ANSI_UNDERLINE)$s$($ANSI_END)"
}
#endregion

#region [Variables]

<#
The variable functions may be better placed in the profile file
#>

function VarExists([string] $name) {

	$errPref = $ErrorActionPreference
  
	$ErrorActionPreference = 'SilentlyContinue'

	$b = !($null -eq (Get-Variable -Name $name));

	$ErrorActionPreference = $errPref

	return $b
}

<#
.Description
Assigns a specified value to a ref input variable if the ref input variable is null or does not exist 
#>
function VarAssign([ref]$name, $val) {
	
	#https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_ref?view=powershell-7.1
	#https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_variables?view=powershell-7.1

	if (!($name) -or !($name.HasValue) -or ($name -eq $null)) {
		$name.Value = $val
	}
}



function Set-SpecialVar {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string][ValidateNotNullOrEmpty()]$n,

		[Parameter(Mandatory = $true)]
		[string][ValidateNotNullOrEmpty()]$v,
		
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ScopedItemOptions]$o,

		[Parameter(Mandatory = $false)]
		[string]$s
	)

	if (!($s)) {
		$s = 'global'
	}

	$errPref = $ErrorActionPreference
  
	$ErrorActionPreference = 'SilentlyContinue'

	try {
		Set-Variable -Name $n -Value $v -Scope $s -Option $o
	}
	catch {
		#Write-Debug "Constant value $name not written"
	}
	finally {
		$ErrorActionPreference = $errPref
		Write-Verbose "$name = $value"
	}
	
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
		[Parameter(Mandatory = $true, Position = 0)]
		[string][ValidateNotNullOrEmpty()]$name,
  
		[Parameter(Mandatory = $true, Position = 1)]
		[char][ValidateSet('=')]$link,
  
		[Parameter(Mandatory = $true, Position = 2)]
		[object][ValidateNotNullOrEmpty()]$value
  
		#[Parameter(Mandatory=$false, Position=3)]
		#[ValidateSet("r")]
		#[object][ValidateNotNullOrEmpty()]$arg,
	)

	Set-SpecialVar -n $name -v $value -o ([System.Management.Automation.ScopedItemOptions]::Constant)
}

Set-Alias const Set-Constant



function Set-Readonly {
	
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string][ValidateNotNullOrEmpty()]$name,
  
		[Parameter(Mandatory = $true, Position = 1)]
		[char][ValidateSet('=')]$link,
  
		[Parameter(Mandatory = $true, Position = 2)]
		[object][ValidateNotNullOrEmpty()]$value
  
		#[Parameter(Mandatory=$false, Position=3)]
		#[ValidateSet("r")]
		#[object][ValidateNotNullOrEmpty()]$arg,
	)

	Set-SpecialVar -n $name -v $value -o ([System.Management.Automation.ScopedItemOptions]::ReadOnly)
	
}

Set-Alias readonly Set-Readonly

#endregion

#region [Collections]

function Flatten($a) {
	, @($a | ForEach-Object { $_ })
}

function Get-Difference {
	param (
		[Parameter(Mandatory = $true)][object[]]$a,
		[Parameter(Mandatory = $true)][object[]]$b
	)
	
	return $b | Where-Object { ($a -notcontains $_) }
}

function Get-Intersection {
	param (
		[Parameter(Mandatory = $true)][object[]]$a,
		[Parameter(Mandatory = $true)][object[]]$b
	)
	return Compare-Object $a $b -PassThru -IncludeEqual -ExcludeDifferent
}

function Get-Union {
	param (
		[Parameter(Mandatory = $true)][object[]]$a,
		[Parameter(Mandatory = $true)][object[]]$b
	)
	return Compare-Object $a $b -PassThru -IncludeEqual
}

#endregion

#region [Other]


function ConvertTo-Gif {
	param (
		[Parameter(Mandatory = $true)][string]$x,
		[Parameter(Mandatory = $true)][string]$y
	)
	
	#ffmpeg -i <input> -vf “fps=25,scale=1920:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse” <output gif>

	ffmpeg -i $x -vf 'fps=25,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse' $y

}


function Get-Translation {
	param (
		[Parameter(Mandatory = $true)][string]$x,
		[Parameter(Mandatory = $true)][string]$y
	)

	$cmd = "from googletrans import * `n" + `
		"tmp = Translator().translate('$x', dest='$y')`n" + `
		"print('{0} ({1})'.format(tmp.text, tmp.pronunciation))`n"
	

	$out1 = (python -c $cmd)

	$cmd2 = "from translatepy import * `n" + `
		"tmp2 = Translator().translate('$x', '$y')`n" + `
		'print(tmp2)'

	$out2 = (python -c $cmd2)

	Write-Host "[#1] $out1"
	Write-Host "[#2] $out2"
}
#endregion