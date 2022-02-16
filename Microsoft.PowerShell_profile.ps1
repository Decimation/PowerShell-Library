using namespace Microsoft.PowerShell

<#
# Profile
#>

#region [Modules]

$global:PSROOT = "$HOME\Documents\PowerShell\"

$global:ModulePathRoot = "$PSROOT\Modules\"
$global:ScriptPathRoot = "$PSROOT\Scripts\"

$PSModuleAutoLoadingPreference = [System.Management.Automation.PSModuleAutoLoadingPreference]::All


<# $LocalScripts = (Get-ChildItem $global:ScriptPathRoot) | Where-Object {
	[System.IO.File]::Exists($_)
} | ForEach-Object {
	$_.ToString()
} #>


<#$global:WinPSRoot = "$env:WINDIR\System32\WindowsPowerShell\v1.0\"
$global:WinModulePathRoot = "$WinPSRoot\Modules\"
$global:WinModules = gci "$WinModulePathRoot" | % {
	$_.FullName
}#>

#https://github.com/WantStuff/AudioDeviceCmdlets

Import-Module AudioDeviceCmdlets


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


function Reload-Module {
	param ($x)
	Remove-Module $x
	Import-Module -Force -DisableNameChecking $x
	
}

Import-Module -DisableNameChecking PSKantan
# Import-Module 'C:\Library\vcpkg\scripts\posh-vcpkg'

#endregion

$script:CallerVariableModule = {
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
				[Parameter(ValueFromPipeline)]
				[string]$Value,
				[Parameter(Position = 1)]
				$Name
			)
			process {
				$PSCmdlet.SessionState.PSVariable.Set($Name, $Value)
			}
		}
	} | Import-Module
}

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

Set-Alias -Name wh -Value Write-Host
Set-Alias -Name wd -Value Write-Debug

Set-Alias -Name so -Value Select-Object
Set-Alias -Name ss -Value Select-String
Set-Alias gpr Get-Process
Set-Alias -Name ie -Value Invoke-Expression

<#
#	%	Foreach-Object
#	? 	Where-Object
#	^	Select-Object
#	~ 	Select-String
#	**	Get-Command
#	
#>

Set-Alias ^ Select-Object
Set-Alias ~ Select-String
Set-Alias ** Get-Command


$global:CommonLocation = "$env:USERPROFILE\Downloads" 

function Set-LocationToCommon {
	Set-Location $CommonLocation
}

# Set-Alias cdc Set-LocationToCommon

$script:fr = [string] {
	Reload-Module PSKantan
}
$script:qr = ".`$PROFILE; $fr"

$global:Downloads = "$env:USERPROFILE\Downloads\"

$InformationPreference = 'Continue'
$DebugPreference = 'SilentlyContinue'

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'
$OutputEncoding = [System.Text.Encoding]::UTF8

function New-PInvoke {
	param (
		$imports,
		$className,
		$dll,
		$returnType,
		$funcName,
		$funcParams
	)
	
	Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;

$imports

public static class $className
{
	[DllImport("$dll", SetLastError = true, CharSet = CharSet.Unicode)]
	public static extern $returnType $funcName($funcParams);
}
"@
}
#region 

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

try {
	Set-PSReadLineOption -Colors @{
		CommandColor                = "`e[93m"
		CommentColor                = "`e[32m"
		ContinuationPromptColor     = "`e[37m"
		DefaultTokenColor           = "`e[38;5;255m"
		EmphasisColor               = "`e[96m"
		ErrorColor                  = "`e[91m"
		InlinePredictionColor       = "`e[90m"
		KeywordColor                = "`e[38;5;204m"
		ListPredictionColor         = "`e[33m"
		ListPredictionSelectedColor = "`e[48;5;238m"
		MemberColor                 = "`e[38;2;221;17;221m"
		NumberColor                 = "`e[97m"
		OperatorColor               = "`e[90m"
		ParameterColor              = "`e[38;2;255;255;0m"
		SelectionColor              = "`e[30;47m"
		StringColor                 = "`e[36m"
		TypeColor                   = "`e[38;2;0;255;34m"
		VariableColor               = "`e[92m"
	}
}
catch {
	Write-Verbose ''
}

function Get-PSConsoleReadlineOptions {
	return [Microsoft.PowerShell.PSConsoleReadLine]::GetOptions()
}

$TogglePredictionView = {
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

& $OtherKeyHandlers

#endregion
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$script:LoadTime = (Get-Date -Format 'HH:mm:ss')

Write-Debug "[$env:USERNAME] Loaded profile ($LoadTime)"

Invoke-Expression "$(thefuck --alias)"