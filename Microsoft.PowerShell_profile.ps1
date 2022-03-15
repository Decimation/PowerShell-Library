using namespace Microsoft.PowerShell

<#
# Profile
#>


$global:PSROOT = "$HOME\Documents\PowerShell\"

$global:PSModuleRoot = "$PSROOT\Modules\"
$global:PSScriptRoot = "$PSROOT\Scripts\"

$PSModuleAutoLoadingPreference = [System.Management.Automation.PSModuleAutoLoadingPreference]::All

function Reload-Module {
	param ($x)
	Remove-Module $x
	Import-Module -Force -DisableNameChecking $x
}

Import-Module -DisableNameChecking PSKantan

# https://stackoverflow.com/questions/46528262/is-there-any-way-for-a-powershell-module-to-get-at-its-callers-scope
	
New-Module {
	function Get-CallerVariable {
		param (
			[Parameter(Position = 1)]
			[string]$Name
		)
		$PSCmdlet.SessionState.PSVariable.GetValue($Name)
	}
	function Set-CallerVariable {
		param (
			[Parameter(ValuefromPipeline)]
			[string]$Value,
			[Parameter(Position = 1)]
			$Name
		)
		process {
			$PSCmdlet.SessionState.PSVariable.Set($Name, $Value)
		}
	}
} | Import-Module

function Prompt {
	
	$fg2 = [System.ConsoleColor]::Green
	$fg1 = [System.ConsoleColor]::Blue
	
	Write-Host 'PS ' -NoNewline -ForegroundColor $fg1
	$currentDate = $(Get-Date -Format 'HH:mm:ss')
	Write-Host ("[$currentDate] ") -NoNewline -ForegroundColor $fg2
	Write-Host "$(Get-Location)" -NoNewline
	Write-Host '>' -NoNewline
	
	return ' '
}

# region Aliases

Set-Alias -Name wh -Value Write-Host
Set-Alias -Name wd -Value Write-Debug
Set-Alias -Name ie -Value Invoke-Expression

<#
#	%	Foreach-Object
#	? 	Where-Object
#	^	Select-Object
#	~ 	Select-String
#	
#	
#>

Set-Alias ^ Select-Object
Set-Alias ~ Select-String


# endregion

$script:rmpsk = [string] {
	Import-Module PSKantan -Force -DisableNameChecking
}

$script:rmpsk2 = [string] {
	Reload-Module PSKantan
}

$script:qr = ".`$PROFILE; $rmpsk"
$script:qr2 = ".`$PROFILE; $rmpsk2"

$global:Downloads = "$env:USERPROFILE\Downloads\"

# region 
$InformationPreference = 'Continue'
$ErrorActionPreference = 'Inquire'
$DebugPreference = 'Continue'

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$OutputEncoding = [System.Text.Encoding]::UTF8

$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'
# endregion


#region Keys

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

Set-PSReadLineOption -Colors @{
	Command                = "$([char]0x1b)[93;1m"
	# Command                = '#d6c956'
	Comment                = "$([char]0x1b)[32m"
	ContinuationPrompt     = "$([char]0x1b)[37m"
	Emphasis               = "`e[38;5;166m"
	Error                  = "$([char]0x1b)[91m"
	InlinePrediction       = "$([char]0x1b)[0;90m"
	# Keyword                = "$([char]0x1b)[38;5;204m"
	Keyword                = "$([char]0x1b)[38;5;27;1m"
	ListPrediction         = "$([char]0x1b)[33m"
	ListPredictionSelected = "$([char]0x1b)[48;5;234;4m"
	# Member                 = '#BEB7FF'
	# Member                 = '#ff3690'
	Member                 = "$([char]0x1b)[38;5;170m"
	# Number                 = '#dad27e'
	Number                 = '#73fff6'
	# Number                 = "$([char]0x1b)[38;5;136m"
	# Operator               = "$([char]0x1b)[38;5;254m"
	Operator               = "$([char]0x1b)[38;5;166m"
	Parameter              = "$([char]0x1b)[38;2;255;165;0;3m"
	Selection              = "$([char]0x1b)[30;47m"
	String                 = "$([char]0x1b)[38;5;215m"
	Variable               = "$([char]0x1b)[38;2;0;255;34m"
	# Type                   = '#9CDCFE'
	Type                   = "$([char]0x1b)[38;5;81;1m"
}

function Get-PSConsoleReadlineOptions {
	return [Microsoft.PowerShell.PSConsoleReadLine]::GetOptions()
}

function script:Clear-PSLine {
	<# $a = ''
	$b = 0
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$a, [ref]$b)
	[Microsoft.PowerShell.PSConsoleReadLine]::DeleteLine()
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert($a) #>
	[Microsoft.PowerShell.PSConsoleReadLine]::DeleteLine()

}

$TogglePredictionView = {
	Clear-PSLine
	[Microsoft.PowerShell.PSConsoleReadLine]::SwitchPredictionView()
	
	$pvs = (Get-PSConsoleReadlineOptions).PredictionViewStyle
	
	if ($pvs -eq 'ListView') {
		& $ListViewHandler
	}
	else {
		& $InlineViewHandler
	}
	& $OtherKeyHandlers
	$pvs = (Get-PSConsoleReadlineOptions).PredictionViewStyle
	
	
	[PSConsoleReadLine]::AcceptLine()
	Write-Host 'Prediction view: ' -NoNewline
	Write-Host "$pvs" -ForegroundColor DarkCyan
}

Set-PSReadlineKeyHandler -Key F2 -ScriptBlock $TogglePredictionView


$ListViewHandler = {
	Set-PSReadLineKeyHandler -Key 'Ctrl+UpArrow' -Function PreviousSuggestion
	Set-PSReadLineKeyHandler -Key 'Ctrl+DownArrow' -Function NextSuggestion
}

$InlineViewHandler = {
	Set-PSReadlineKeyHandler -Key 'Tab' -Function AcceptNextSuggestionWord
	Set-PSReadlineKeyHandler -Chord 'Ctrl+Tab' -Function AcceptSuggestion
}

& $InlineViewHandler

$OtherKeyHandlers = {
	Set-PSReadLineKeyHandler -Key 'Tab' -Function TabCompleteNext
	Set-PSReadlineKeyHandler -Key 'Shift+Tab' -Function TabCompletePrevious
	Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
	Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
	Set-PSReadLineKeyHandler -Key 'Ctrl+UpArrow' -Function PreviousHistory
	Set-PSReadLineKeyHandler -Key 'Ctrl+DownArrow' -Function NextHistory
	Set-PSReadLineKeyHandler -Key 'Tab' -Function TabCompleteNext
	Set-PSReadLineKeyHandler -Key F1 -Function ShowCommandHelp
	Set-PSReadLineKeyHandler -Key 'Ctrl+p' -Function ShowParameterHelp
	Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function ForwardWord
}


Set-PSReadLineKeyHandler -Key F3 -ScriptBlock {
	Write-Host
	Write-Host 'Popped:' -ForegroundColor DarkYellow
	Pop-Location -PassThru | Out-Host
	[PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key F4 -ScriptBlock {
	Write-Host
	Write-Host 'Pushed:' -ForegroundColor DarkYellow
	Push-Location -PassThru | Out-Host 
	
	[PSConsoleReadLine]::AcceptLine()
	# $Host.ui.WriteLine()
}


Set-PSReadLineKeyHandler -Key F5 -ScriptBlock {
	ie $qr
	[PSConsoleReadLine]::AcceptLine()
	Write-Host 'Reloaded profile' -ForegroundColor DarkGreen
	[PSConsoleReadLine]::Ding()
}

Set-PSReadLineKeyHandler -Key 'Ctrl+F5' -ScriptBlock {
	ie $qr2
	[PSConsoleReadLine]::AcceptLine()
	Write-Host 'Reloaded profile full' -ForegroundColor DarkGreen
	[PSConsoleReadLine]::Ding()
}

& $OtherKeyHandlers

$script:ap = [System.Enum]::GetValues([System.Management.Automation.ActionPreference]) `
	-notmatch 'Suspend'

Set-PSReadLineKeyHandler -Key F6 -ScriptBlock {
	$idx = Wrap ($script:ap.IndexOf($global:DebugPreference) + 1) ($script:ap.Count)
	$global:DebugPreference = $script:ap[$idx]
	[PSConsoleReadLine]::AcceptLine()
	Write-Host 'Debug preference: ' -NoNewline -ForegroundColor Yellow
	Write-Host "$global:DebugPreference" -ForegroundColor Green
	[PSConsoleReadLine]::Ding()

}
function Wrap { param($i, $n) return (($i % $n) + $n) % $n }

Set-PSReadLineKeyHandler -Key F7 -ScriptBlock {
	$idx = Wrap ($script:ap.IndexOf($global:ErrorActionPreference) + 1) ($script:ap.Count)
	$global:ErrorActionPreference = $script:ap[$idx]
	[PSConsoleReadLine]::AcceptLine()
	Write-Host 'Error action preference: ' -NoNewline -ForegroundColor Yellow
	Write-Host "$global:ErrorActionPReference" -ForegroundColor Green
	[PSConsoleReadLine]::Ding()

}
#endregion

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$script:LoadTime = (Get-Date -Format 'HH:mm:ss')

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
	param ($commandName, $wordToComplete, $cursorPosition)
	dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}

function New-AdminWT {
	sudo wt -w 0 nt
}


#Invoke-Expression "$(thefuck --alias)"
# Install-Module -Name Terminal-Icons -Repository PSGallery
# Install-Module oh-my-posh -Scope CurrentUser

Import-Module ZLocation
Import-Module oh-my-posh
#https://github.com/WantStuff/AudioDeviceCmdlets
Import-Module AudioDeviceCmdlets
# Set-PoshPrompt microverse-power