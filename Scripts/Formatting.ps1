$script:UNI_ARROW = $([char]0x2192)
$script:SEPARATOR = $([string]::new('-', $Host.UI.RawUI.WindowSize.Width))

$private:ANSI_UNDERLINE = "$([char]0x1b)[4m"
$private:ANSI_END = "$([char]0x001b)[0m"

function Get-Underline {
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[string]$s
	)
	
	return "$($ANSI_UNDERLINE)$s$($ANSI_END)"
}

function Get-CenteredString { 
	param ($Message)
	return ('{0}{1}' -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($Message.Length / 2)))), $Message)
}