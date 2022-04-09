using namespace System.Management.Automation.Language
using namespace Microsoft.PowerShell



<#
# Profile
#>

$global:PSROOT = "$HOME\Documents\PowerShell\"
$global:PSModules = Join-Path $global:PSROOT "\Modules\"
$global:PSScripts = Join-Path "$global:PSROOT" "\Scripts\"

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

function QText {

	param (
		[Parameter(Mandatory, Position = 0)]
		$Value,
		[Parameter(Mandatory = $false)]
		[ArgumentCompletions('bold', 'italic', 'underline', '')]
		$styles = '',
		[Parameter(ValueFromRemainingArguments, Mandatory = $false)]
		$d
	)
	$global:ANSI_END = "`e[0m"

	$ht = @{
		bold      = 1
		italic    = 3
		underline = 4
	}
	if ($styles -eq '') {
		$sb = $Value
	}
	else {
		$sb = "`e[" 
		$rg = @()
		$styles -split ',' | ForEach-Object { 
			$rg += $ht.$_
		}
		
		$sb += "$($rg -join ';')m"
		
	}
	return New-Text "$sb$Value$ANSI_END" @d
}

function Prompt {
	
	$cd = Get-Location
	# $p1 = ""
	$p1 = ""
	$ps = "PS "

	$user = $env:USERNAME
	$cname = $env:COMPUTERNAME
	
	$u = Text "`e[1m$user$ANSI_END" -ForegroundColor 220
	$c = Text "`e[3m$cname$ANSI_END" -ForegroundColor 40
	$p = Text "`e[1m$ps$ANSI_END" -ForegroundColor 'orange'
	$f = Text "`e[4m$cd$ANSI_END" -ForegroundColor 'cyan'
	$l = Text "$p1" -ForegroundColor 'yellow'
	$d = Text " $(Get-Date -Format "HH:mm:ss") " -ForegroundColor 'pink'

	Write-Host $($p, $u, "@", $c, $d, $f, "`n", "$l" ) -NoNewline -Separator ''

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

$private:ImportThis = [string] {
	Import-Module PSKantan -Force -DisableNameChecking
}

$private:ReloadThis = [string] {
	Reload-Module PSKantan
}

#Note: ie $qr	| Re-imports profile and PSKantan
#Note: ie $qr2	| Re-imports profile, removes PSKantan and then re-imports it

$script:qr = ".`$PROFILE; $ImportThis"
$script:qr2 = ".`$PROFILE; $ReloadThis"


# region 

# region Preferences

$InformationPreference = 'Continue'
$ErrorActionPreference = 'Continue'
$DebugPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

# endregion

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'
$PSModuleAutoLoadingPreference = [System.Management.Automation.PSModuleAutoLoadingPreference]::All
$OutputEncoding = [System.Text.Encoding]::UTF8

$script:ActionPreferences = [System.Enum]::GetValues([System.Management.Automation.ActionPreference]) `
	-notmatch 'Suspend'

[Net.ServicePointManager]::SecurityProtocol = `
	[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# endregion

#region Keys

$script:contchar = "~"
$script:cont = "$contchar"

# $script:cont = "`e[38;5;226m$contchar$ANSI_END"

Set-PSReadLineOption `
	-PredictionSource HistoryAndPlugin `
	-HistorySearchCursorMovesToEnd `
	-ShowToolTips `
	-MaximumHistoryCount 10000 `
	-ContinuationPrompt $script:cont `
	-AddToHistoryHandler {
	param([string]$line)
	return $line;
}

Set-PSReadLineOption -Colors @{
	Command                = "$([char]0x1b)[93;1m"
	Comment                = "$([char]0x1b)[32m"
	ContinuationPrompt     = "$([char]0x1b)[37m"
	Emphasis               = "`e[38;5;166m"
	Error                  = "$([char]0x1b)[91m"
	InlinePrediction       = "$([char]0x1b)[0;90m"
	Keyword                = "$([char]0x1b)[38;5;33;1m"
	ListPrediction         = "$([char]0x1b)[33m"
	ListPredictionSelected = "$([char]0x1b)[48;5;234;4m"
	Member                 = "$([char]0x1b)[38;5;170m"
	Number                 = '#73fff6'
	Operator               = "$([char]0x1b)[38;5;166m"
	Parameter              = "$([char]0x1b)[38;2;255;165;0;3m"
	Selection              = "$([char]0x1b)[7m"
	String                 = "$([char]0x1b)[38;5;45m"
	Variable               = "$([char]0x1b)[38;2;0;255;34m"
	Type                   = "$([char]0x1b)[38;5;81;1m"
}



$global:KeyMappings = @(
	@{
		Key      = 'Tab'
		Function = 'MenuComplete'
	}, 
	@{
		Key      = 'Ctrl+Tab'
		Function = 'AcceptSuggestion'
	}, 
	@{
		Key      = 'Ctrl+q'
		Function = 'TabCompleteNext'
	}, 
	@{
		Key      = 'Ctrl+y'
		Function = 'Yank'
	}, 
	@{
		Key      = 'Ctrl+x'
		Function = 'Cut'
	},
	@{
		Key      = 'Shift+Tab' 
		Function = 'TabCompletePrevious'
	}, 
	@{
		Key      = 'Ctrl+UpArrow'
		Function = 'HistorySearchBackward'
	},
	@{
		Key      = 'Ctrl+DownArrow'
		Function = 'HistorySearchForward'
	},
	@{
		Key      = 'DownArrow'
		Function = 'NextHistory'
	}, 
	@{
		Key      = 'UpArrow'
		Function = 'PreviousHistory'
	},
	@{
		Key      = 'F1'
		Function = 'ShowCommandHelp'
	}, 
	@{
		Key      = 'Ctrl+p'
		Function = 'ShowParameterHelp'
	}, 
	@{
		Key      = 'Ctrl+d'
		Function = 'ForwardWord'
	},
	@{
		Key      = 'Ctrl+v'
		Function = 'Paste'
	},
	@{
		Key      = 'Ctrl+x'
		Function = 'KillRegion'
	},
	@{
		Key      = 'Ctrl+c'
		Function = 'CopyOrCancelLine'
	},
	@{
		Key      = 'Alt+w'
		Function = 'SelectNextWord'
	},
	@{
		Key      = 'Alt+Ctrl+w'
		Function = 'SelectBackwardWord'
	},
	@{
		Key      = 'Alt+a'
		Function = 'SelectCommandArgument'
	},
	@{
		<#
		Moves cursor to beginning of line, inserts template for declaring/modifying
		a variable, and selects its name
		#>
		Key         = 'Alt+Ctrl+x'
		ScriptBlock = {
			# [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(0)
			[PSConsoleReadLine]::BeginningOfLine()
			[Microsoft.PowerShell.PSConsoleReadLine]::Insert('$x = ')
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(1)
			[Microsoft.PowerShell.PSConsoleReadLine]::SelectShellForwardWord($null, $null)
		}
	},
	@{
		Key         = 'F3'
		ScriptBlock = {
			Write-Host
			Write-Host 'Popped:' -ForegroundColor DarkYellow
			Pop-Location -PassThru | Out-Host
			[PSConsoleReadLine]::AcceptLine()
		}
	},
	@{
		<#
		Moves to index of character in the buffer
		#>
		Key         = 'Alt+Ctrl+b'
		ScriptBlock = {
			$c = '-'

			$line = $null
			$cursor = $null
			[Microsoft.PowerShell.PSConsoleReadLine]::BeginningOfLine($null, $null)  
			[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
			$global:CharBufferIndex = $line.IndexOf($c, $global:CharBufferIndex)
			#[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
			# Write-Host
			# Write-Host "$global:CharBufferIndex | $cursor | $line"
			$global:CharBufferIndex++
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($global:CharBufferIndex)

		}
	},
	@{
		Key         = 'F4'
		ScriptBlock = {
			Write-Host
			Write-Host 'Pushed:' -ForegroundColor DarkYellow
			Push-Location -PassThru | Out-Host 
			[PSConsoleReadLine]::AcceptLine()
			# $Host.ui.WriteLine()
		}
	},
	@{
		Key         = 'F5'
		ScriptBlock = {
			ie $qr
			[PSConsoleReadLine]::AcceptLine()
			Write-Host 'Reloaded profile' -ForegroundColor DarkGreen
			[PSConsoleReadLine]::Ding()
		}
	},
	@{
		Key         = 'Ctrl+F5' 
		ScriptBlock = {
			ie $qr2
			[PSConsoleReadLine]::AcceptLine()
			Write-Host 'Reloaded profile full' -ForegroundColor DarkGreen
			[PSConsoleReadLine]::Ding()
		}
	},
	@{
		Key         = 'F6'
		ScriptBlock = {
			$idx = Wrap ($script:ActionPreferences.IndexOf($global:DebugPreference) + 1) ($script:ActionPreferences.Count)
			$global:DebugPreference = $script:ActionPreferences[$idx]
			[PSConsoleReadLine]::AcceptLine()
			Write-Host 'Debug preference: ' -NoNewline -ForegroundColor Yellow
			Write-Host "$global:DebugPreference" -ForegroundColor Green
			[PSConsoleReadLine]::Ding()
		}
	},
	@{
		Key         = 'F7'
		ScriptBlock = {
			$idx = Wrap ($script:ActionPreferences.IndexOf($global:ErrorActionPreference) + 1) ($script:ActionPreferences.Count)
			$global:ErrorActionPreference = $script:ActionPreferences[$idx]
			[PSConsoleReadLine]::AcceptLine()
			Write-Host 'Error action preference: ' -NoNewline -ForegroundColor Yellow
			Write-Host "$global:ErrorActionPreference" -ForegroundColor Green
			[PSConsoleReadLine]::Ding()
		}
	},
	@{
		Key         = 'F8'
		ScriptBlock = {
			$idx = Wrap ($script:ActionPreferences.IndexOf($global:VerbosePreference) + 1) ($script:ActionPreferences.Count)
			$global:VerbosePreference = $script:ActionPreferences[$idx]
			[PSConsoleReadLine]::AcceptLine()
			Write-Host 'Verbose preference: ' -NoNewline -ForegroundColor Yellow
			Write-Host "$global:VerbosePreference" -ForegroundColor Green
			[PSConsoleReadLine]::Ding()
		}
	}
) | ForEach-Object { Set-PSReadLineKeyHandler @_ }





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

$global:LoadTime = (Get-Date -Format 'HH:mm:ss')

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
# Install-Module Pansies -AllowClobber

#Install-Module WslInterop
#Import-WslCommand

#Install-Module WindowsCompatibility -Scope CurrentUser
#Import-Module WindowsCompatability

<# Import-Module ZLocation
Import-Module oh-my-posh
Import-Module AudioDeviceCmdlets #>

#https://github.com/WantStuff/AudioDeviceCmdlets
# Set-PoshPrompt microverse-power
# Install-Module -Name GuiCompletion -Scope CurrentUser
