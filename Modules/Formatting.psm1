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