<#
# General utilities
#>


function ConvertTo-Gif {
	param (
		[Parameter(Mandatory=$true)]	[string]	$x,
		[Parameter(Mandatory=$true)]	[string]	$y
	)
	
	#ffmpeg -i <input> -vf “fps=25,scale=1920:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse” <output gif>

	ffmpeg -i $x -vf “fps=25,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse” $y

}


function Get-Translation {
	param (
		[Parameter(Mandatory=$true)]	[string]	$x,
		[Parameter(Mandatory=$true)]	[string]	$y
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

<#
# Formatting utilities
#>


<#----------------------------------------------------------------------------#>


const ANSI_UNDERLINE = "$([char]0x1b)[4m"
const ANSI_END = "$([char]0x001b)[0m"

function Get-Underline {
	param (
		[Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
		[string]$s
	)
	
	return "$($ANSI_UNDERLINE)$s$($ANSI_END)"
}