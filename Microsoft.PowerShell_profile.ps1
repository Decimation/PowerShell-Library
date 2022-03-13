using namespace Microsoft.PowerShell

<#
# Profile
#>

#region [Modules]

$global:PSROOT = "$HOME\Documents\PowerShell\"

$global:ModulePathRoot = "$PSROOT\Modules\"
$global:ScriptPathRoot = "$PSROOT\Scripts\"

$PSModuleAutoLoadingPreference = [System.Management.Automation.PSModuleAutoLoadingPreference]::All



# region Windows PWSH

<#$global:WinPSRoot = "$env:WINDIR\System32\WindowsPowerShell\v1.0\"
$global:WinModulePathRoot = "$WinPSRoot\Modules\"
$global:WinModules = gci "$WinModulePathRoot" | % {
	$_.FullName
}#>

<#function __Import-WinModule {
	param ($name)
	Import-Module $name -UseWindowsPowerShell -NoClobber -WarningAction SilentlyContinue
}

#Get-PSSession -Name WinPSCompatSession

function __Get-WinSession {
	return Get-PSSession -Name WinPSCompatSession
}

function __Invoke-WinCommand {
	param ([scriptblock]$x)
	Invoke-Command -Session $(__Get-WinSession) $x
}#>

#Import-WinModule Appx
#Import-WinModule PnpDevice
#Import-WinModule Microsoft.PowerShell.Management

#https://github.com/PowerShell/WindowsCompatibility

#Install-Module WindowsCompatibility -Scope CurrentUser
#Import-Module WindowsCompatability

# endregion


function Reload-Module {
	param ($x)
	Remove-Module $x
	Import-Module -Force -DisableNameChecking $x
	
}

Import-Module -DisableNameChecking PSKantan

#https://github.com/WantStuff/AudioDeviceCmdlets


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

$InformationPreference = 'Continue'
$DebugPreference = 'SilentlyContinue'

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$OutputEncoding = [System.Text.Encoding]::UTF8

$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'


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
	Member                 = '#ff3690'
	# Number                 = '#dad27e'
	Number                 = '#73fff6'
	# Operator               = "$([char]0x1b)[38;5;254m"
	Operator               = "$([char]0x1b)[36m"
	Parameter              = "$([char]0x1b)[38;2;255;165;0;3m"
	Selection              = "$([char]0x1b)[30;47m"
	String                 = "$([char]0x1b)[38;5;136m"
	Variable               = "$([char]0x1b)[38;2;0;255;34m"
	Type                   = '#9CDCFE'
}

function Get-PSConsoleReadlineOptions {
	return [Microsoft.PowerShell.PSConsoleReadLine]::GetOptions()
}

$TogglePredictionView = {
	[Microsoft.PowerShell.PSConsoleReadLine]::DeleteLine()
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
	# $Host.ui.WriteLine('Reloaded profile')
	[PSConsoleReadLine]::Ding()
}
Set-PSReadLineKeyHandler -Key 'Ctrl+F5' -ScriptBlock {
	ie $qr2
	[PSConsoleReadLine]::AcceptLine()
	Write-Host 'Reloaded profile full' -ForegroundColor DarkGreen
	# $Host.ui.WriteLine('Reloaded profile')
	[PSConsoleReadLine]::Ding()
}
& $OtherKeyHandlers

#endregion

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$script:LoadTime = (Get-Date -Format 'HH:mm:ss')

Write-Debug "[$env:USERNAME] Loaded profile ($LoadTime)"

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
	param ($commandName, $wordToComplete, $cursorPosition)
	dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}

#Invoke-Expression "$(thefuck --alias)"

Import-Module ZLocation
# Install-Module -Name Terminal-Icons -Repository PSGallery
# Install-Module oh-my-posh -Scope CurrentUser
Import-Module oh-my-posh
# Set-PoshPrompt microverse-power
Import-Module AudioDeviceCmdlets
