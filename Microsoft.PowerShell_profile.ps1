using namespace System.Management.Automation.Language
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
$ErrorActionPreference = 'Continue'
$DebugPreference = 'Continue'

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$OutputEncoding = [System.Text.Encoding]::UTF8

$script:ap = [System.Enum]::GetValues([System.Management.Automation.ActionPreference]) `
	-notmatch 'Suspend'

$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'
# endregion

function Wrap { param($i, $n) return (($i % $n) + $n) % $n }

#region Keys

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadlineOption -ShowToolTips
Set-PSReadLineOption -MaximumHistoryCount 10000

Set-PSReadLineOption -AddToHistoryHandler {
	<# param([string]$line)

	$sensitive = password | asplaintext | token | key | secret
	return ($line -notmatch $sensitive) #>
	param([string]$line)
	return $line;
}

Set-PSReadLineOption -Colors @{
	Command                = "$([char]0x1b)[93;1m"
	# Command                = '#d6c956'
	Comment                = "$([char]0x1b)[32m"
	ContinuationPrompt     = "$([char]0x1b)[37m"
	Emphasis               = "`e[38;5;166m"
	Error                  = "$([char]0x1b)[91m"
	InlinePrediction       = "$([char]0x1b)[0;90m"
	# Keyword                = "$([char]0x1b)[38;5;204m"
	Keyword                = "$([char]0x1b)[38;5;33;1m"
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
	Selection              = "$([char]0x1b)[48;5;250;38;5;0m"
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
	# Set-PSReadlineKeyHandler -Key 'Tab' -Function AcceptNextSuggestionWord
	Set-PSReadlineKeyHandler -Chord 'Ctrl+Tab' -Function AcceptSuggestion
}

& $InlineViewHandler

$OtherKeyHandlers = {
	#Set-PSReadLineKeyHandler -Key 'Tab' -Function TabCompleteNext
	Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
	Set-PSReadlineKeyHandler -Key 'Shift+Tab' -Function TabCompletePrevious
	Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
	Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
	Set-PSReadLineKeyHandler -Key 'Ctrl+UpArrow' -Function PreviousHistory
	Set-PSReadLineKeyHandler -Key 'Ctrl+DownArrow' -Function NextHistory
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


Set-PSReadLineKeyHandler -Key F6 -ScriptBlock {
	$idx = Wrap ($script:ap.IndexOf($global:DebugPreference) + 1) ($script:ap.Count)
	$global:DebugPreference = $script:ap[$idx]
	[PSConsoleReadLine]::AcceptLine()
	Write-Host 'Debug preference: ' -NoNewline -ForegroundColor Yellow
	Write-Host "$global:DebugPreference" -ForegroundColor Green
	[PSConsoleReadLine]::Ding()

}


Set-PSReadLineKeyHandler -Key F7 -ScriptBlock {
	$idx = Wrap ($script:ap.IndexOf($global:ErrorActionPreference) + 1) ($script:ap.Count)
	$global:ErrorActionPreference = $script:ap[$idx]
	[PSConsoleReadLine]::AcceptLine()
	Write-Host 'Error action preference: ' -NoNewline -ForegroundColor Yellow
	Write-Host "$global:ErrorActionPReference" -ForegroundColor Green
	[PSConsoleReadLine]::Ding()

}


#region Smart Insert/Delete
#https://megamorf.gitlab.io/cheat-sheets/powershell-psreadline/

Set-PSReadLineKeyHandler -Key '"', "'" `
	-BriefDescription SmartInsertQuote `
	-LongDescription 'Insert paired quotes if not already on a quote' `
	-ScriptBlock {
	param($key, $arg)

	$quote = $key.KeyChar

	$selectionStart = $null
	$selectionLength = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	# If text is selected, just quote it without any smarts
	if ($selectionStart -ne -1) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
		return
	}

	$ast = $null
	$tokens = $null
	$parseErrors = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

	function FindToken {
		param($tokens, $cursor)

		foreach ($token in $tokens) {
			if ($cursor -lt $token.Extent.StartOffset) { continue }
			if ($cursor -lt $token.Extent.EndOffset) {
				$result = $token
				$token = $token -as [StringExpandableToken]
				if ($token) {
					$nested = FindToken $token.NestedTokens $cursor
					if ($nested) { $result = $nested }
				}

				return $result
			}
		}
		return $null
	}

	$token = FindToken $tokens $cursor

	# If we're on or inside a **quoted** string token (so not generic), we need to be smarter
	if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
		# If we're at the start of the string, assume we're inserting a new string
		if ($token.Extent.StartOffset -eq $cursor) {
			[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote ")
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
			return
		}

		# If we're at the end of the string, move over the closing quote if present.
		if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
			return
		}
	}

	if ($null -eq $token -or
		$token.Kind -eq [TokenKind]::RParen -or $token.Kind -eq [TokenKind]::RCurly -or $token.Kind -eq [TokenKind]::RBracket) {
		if ($line[0..$cursor].Where{ $_ -eq $quote }.Count % 2 -eq 1) {
			# Odd number of quotes before the cursor, insert a single quote
			[Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
		}
		else {
			# Insert matching quotes, move cursor to be in between the quotes
			[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
		}
		return
	}

	if ($token.Extent.StartOffset -eq $cursor) {
		if ($token.Kind -eq [TokenKind]::Generic -or $token.Kind -eq [TokenKind]::Identifier -or 
			$token.Kind -eq [TokenKind]::Variable -or $token.TokenFlags.hasFlag([TokenFlags]::Keyword)) {
			$end = $token.Extent.EndOffset
			$len = $end - $cursor
			[Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.SubString($cursor, $len) + $quote)
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
			return
		}
	}

	# We failed to be smart, so just insert a single quote
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
}

Set-PSReadLineKeyHandler -Key '(', '{', '[' `
	-BriefDescription InsertPairedBraces `
	-LongDescription 'Insert matching braces' `
	-ScriptBlock {
	param($key, $arg)

	$closeChar = switch ($key.KeyChar) {
		<#case#> '(' { [char]')'; break }
		<#case#> '{' { [char]'}'; break }
		<#case#> '[' { [char]']'; break }
	}

	$selectionStart = $null
	$selectionLength = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    
	if ($selectionStart -ne -1) {
		# Text is selected, wrap it in brackets
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
	}
 else {
		# No text is selected, insert a pair
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
	}
}

Set-PSReadLineKeyHandler -Key ')', ']', '}' `
	-BriefDescription SmartCloseBraces `
	-LongDescription 'Insert closing brace or skip' `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($line[$cursor] -eq $key.KeyChar) {
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
	}
	else {
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
	}
}

Set-PSReadLineKeyHandler -Key Backspace `
	-BriefDescription SmartBackspace `
	-LongDescription 'Delete previous character or matching quotes/parens/braces' `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($cursor -gt 0) {
		$toMatch = $null
		if ($cursor -lt $line.Length) {
			switch ($line[$cursor]) {
				<#case#> '"' { $toMatch = '"'; break }
				<#case#> "'" { $toMatch = "'"; break }
				<#case#> ')' { $toMatch = '('; break }
				<#case#> ']' { $toMatch = '['; break }
				<#case#> '}' { $toMatch = '{'; break }
			}
		}

		if ($toMatch -ne $null -and $line[$cursor - 1] -eq $toMatch) {
			[Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
		}
		else {
			[Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
		}
	}
}

#endregion Smart Insert/Delete

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

#Invoke-Expression "$(thefuck --alias)"
# Install-Module -Name Terminal-Icons -Repository PSGallery
# Install-Module oh-my-posh -Scope CurrentUser

Import-Module ZLocation
Import-Module oh-my-posh
#https://github.com/WantStuff/AudioDeviceCmdlets
Import-Module AudioDeviceCmdlets
# Set-PoshPrompt microverse-power

function global:qprint {
	param($rg)
	return [string]($rg -join ',')
}