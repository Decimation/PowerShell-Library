using namespace System.Management.Automation.Language
using namespace Microsoft.PowerShell


[console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

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

function Prompt {
	
	$cd = Get-Location
	# $p1 = ""
	$p1 = ""
	$ps = "PS "
	# $p2 = "$(U 0x26a1)"
	$user = $env:USERNAME
	$cname = $env:COMPUTERNAME
	
	$u = Text "`e[1m$user$ANSI_END" -ForegroundColor 220
	$c = Text "`e[3m$cname$ANSI_END" -ForegroundColor 40
	$p = Text "`e[1m$ps$ANSI_END" -ForegroundColor 'magenta'
	# $f = Text "`e[4m$cd$ANSI_END" -ForegroundColor 'cyan'
	$f = Text "`e[3m$cd$ANSI_END" -ForegroundColor 'cyan'

	$l = Text "$p1" -ForegroundColor 'yellow'
	$d = Text " $(Get-Date -Format "yyyy-MM-dd @ HH:mm:ss") " -ForegroundColor 'orange'

	Write-Host $($p, $u, "@", $c, $d, $f, " $(U 0x27EB)", "`n", "$l") -NoNewline -Separator ''

	return ' '
}

# region Aliases

Set-Alias -Name wh -Value Write-Host
Set-Alias -Name wd -Value Write-Debug
Set-Alias -Name ie -Value Invoke-Expression
Set-Alias -Name open -Value start
Set-Alias -Name kill -Value kill.exe


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

# region Preferences

$InformationPreference = 'Continue'
$ErrorActionPreference = 'Continue'
$DebugPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

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

Set-PSReadLineOption `
	-PredictionSource HistoryAndPlugin `
	-HistorySearchCursorMovesToEnd `
	-ShowToolTips `
	-CompletionQueryItems 100 `
	-MaximumHistoryCount 10000 `
	-ContinuationPrompt "$(Text "`u{fb0c}" -fg 'orange') " `
	-AddToHistoryHandler {
	param([string]$line)
	return $line;
}

Set-PSReadLineOption -Colors @{
	Command                = "$([char]0x1b)[38;5;220;1m"
	Comment                = "$([char]0x1b)[32m"
	ContinuationPrompt     = "$([char]0x1b)[37m"
	Emphasis               = "`e[38;5;166m"
	Error                  = "$([char]0x1b)[91m"
	InlinePrediction       = "$([char]0x1b)[0;90m"
	Keyword                = "$([char]0x1b)[38;5;33;1m"
	ListPrediction         = "$([char]0x1b)[33m"
	ListPredictionSelected = "$([char]0x1b)[48;5;234;4m"
	Member                 = "$([char]0x1b)[38;5;170m"
	Number                 = '#c4e994'
	Operator               = "$([char]0x1b)[38;5;200m"
	Parameter              = "$([char]0x1b)[38;5;14;3m"
	Selection              = "$([char]0x1b)[7m"
	String                 = "$([char]0x1b)[38;5;166m"
	Variable               = "$([char]0x1b)[38;2;0;255;34m"
	Type                   = "$([char]0x1b)[38;5;81;1m"
}

function Get-BufferState {
	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
	return $line, $cursor
}

$global:KeyMappings = @(
	@{
		Chord    = 'Tab'
		Function = 'MenuComplete'
	}, 
	@{
		Chord    = 'Ctrl+Tab'
		Function = 'AcceptSuggestion'
	}, 
	@{
		Chord    = 'Ctrl+q'
		Function = 'TabCompleteNext'
	}, 
	@{
		Chord    = 'Ctrl+y'
		Function = 'Yank'
	}, 
	@{
		Chord    = 'Alt+y'
		Function = 'BackwardKillLine'
	},
	@{
		Chord    = 'Shift+Tab' 
		Function = 'TabCompletePrevious'
	}, 
	@{
		Chord    = 'Ctrl+UpArrow'
		Function = 'HistorySearchBackward'
	},
	@{
		Chord    = 'Ctrl+DownArrow'
		Function = 'HistorySearchForward'
	},
	@{
		Chord    = 'DownArrow'
		Function = 'NextHistory'
	}, 
	@{
		Chord    = 'UpArrow'
		Function = 'PreviousHistory'
	},
	@{
		Chord    = 'F1'
		Function = 'ShowCommandHelp'
	}, 
	@{
		Chord    = 'Ctrl+F1'
		Function = 'ShowParameterHelp'
	}, 
	@{
		Chord    = 'Ctrl+d'
		Function = 'ForwardWord'
	},
	@{
		Chord    = 'Ctrl+v'
		Function = 'Paste'
	},
	@{
		Chord    = 'Ctrl+x'
		Function = 'Cut'
	},
	@{
		Chord    = 'Ctrl+t'
		Function = 'SwapCharacters'
	}, 
	@{
		Chord    = 'Ctrl+shift+x'
		Function = 'KillRegion'
	},
	@{
		Chord    = 'Ctrl+c'
		Function = 'CopyOrCancelLine'
	},
	@{
		Chord    = 'Alt+s'
		Function = 'SelectNextWord'
	},
	@{
		Chord    = 'Alt+Ctrl+s'
		Function = 'SelectBackwardWord'
	},
	@{
		Chord    = 'Alt+a'
		Function = 'SelectCommandArgument'
	},
	@{
		Chord    = 'Ctrl+F9'
		Function = 'AddLine'
	},
	@{
		<#
		Moves cursor to beginning of line, inserts template for declaring/modifying
		a variable, and selects its name
		#>
		Chord       = 'Ctrl+Alt+x'
		ScriptBlock = {

			# [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(0)
			[PSConsoleReadLine]::BeginningOfLine()
			[Microsoft.PowerShell.PSConsoleReadLine]::Insert('$x = ')
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(1)
			[Microsoft.PowerShell.PSConsoleReadLine]::SelectShellForwardWord($null, $null)
		}
	},
	@{
		# Character search
		
		Chord       = 'Alt+q'
		ScriptBlock = {
			$c = '-'

			$line = $null
			$cursor = $null
			[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
			[Microsoft.PowerShell.PSConsoleReadLine]::BeginningOfLine($null, $null)  
			$global:CharBufferIndex = $line.IndexOf($c, $global:CharBufferIndex)
			#[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
			# Write-Host
			# Write-Host "$global:CharBufferIndex | $cursor | $line"
			$global:CharBufferIndex++
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($global:CharBufferIndex)
		}
	},
	@{
		Chord    = 'Ctrl+p'
		Function = 'AcceptSuggestion'
	},
	@{
		Chord       = 'F5'
		ScriptBlock = {
			ie $qr
			[PSConsoleReadLine]::AcceptLine()
			Write-Host 'Reloaded profile' -ForegroundColor DarkGreen
			[PSConsoleReadLine]::Ding()
		}
	}, 
	@{
		Chord       = 'Ctrl+F5' 
		ScriptBlock = {
			ie $qr2
			[PSConsoleReadLine]::AcceptLine()
			Write-Host 'Reloaded profile full' -ForegroundColor DarkGreen
			[PSConsoleReadLine]::Ding()
		}
	},
	@{
		Chord    = 'F2'
		Function = 'SwitchPredictionView'
	}, 
	@{
		Chord    = 'F3'
		Function = 'CharacterSearch'
	},
	@{
		Chord    = 'Shift+F3'
		Function = 'CharacterSearchBackward'
	},
	@{
		Chord       = 'F6'
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
		Chord       = 'F7'
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
		Chord       = 'F8'
		ScriptBlock = {
			$idx = Wrap ($script:ActionPreferences.IndexOf($global:VerbosePreference) + 1) ($script:ActionPreferences.Count)
			$global:VerbosePreference = $script:ActionPreferences[$idx]
			[PSConsoleReadLine]::AcceptLine()
			Write-Host 'Verbose preference: ' -NoNewline -ForegroundColor Yellow
			Write-Host "$global:VerbosePreference" -ForegroundColor Green
			[PSConsoleReadLine]::Ding()
		}
	},
	@{
		Chord    = 'F4'
		Function = 'RepeatLastCharSearch'
	},
	@{
		Chord    = 'Shift+F4'
		Function = 'RepeatLastCharSearchBackwards'
	}<# ,
	@{
		Chord    = 'F5'
		ScriptBlock={
			$line = $null
			$cursor = $null
			$ast=$null
			[Token[]]$tok=$null
			[ParseError[]]$pe=$null
			[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast,[ref]$tok,[ref]$pe, [ref]$cursor)

			#([ref] System.Management.Automation.Language.Ast ast, [ref] System.Management.Automation.Language.Token[] tokens, [ref] System.Management.Automation.Language.ParseError[] parseErrors, [ref] int cursor)
			

			# $ls=$line.Substring($cursor).Split(' ')

			# $ls|%{

			# 	$c = (Get-Command -Type All $_)
				
			# 	if ($c) {
			# 		Write-Debug "$($global:CharBufferIndex) | $_ | $line | $cursor | $c"
			# 		$global:CharBufferIndex =$line.IndexOf($_,$global:CharBufferIndex)
			# 		[PSConsoleReadLine]::SetCursorPosition($global:CharBufferIndex)
			# 		[PSConsoleReadLine]::SelectShellForwardWord($null, $null)
			# 		$global:CharBufferIndex+=$_.Length
			# 	}
			# }
			Write-Debug "$cursor"
			$tok|%{Write-Debug "$_"}

			$tok|%{
				$c=Get-Command -Type All $_
				if ($c) {
					$global:CharBufferIndex = $line.IndexOf($_, $global:CharBufferIndex)
					[PSConsoleReadLine]::SetCursorPosition($global:CharBufferIndex)
					[PSConsoleReadLine]::SelectShellForwardWord($null, $null)
				}
			}
		}
	} #>
) | ForEach-Object { Set-PSReadLineKeyHandler @_ }

$global:CharBufferIndex = 0

#region Smart Insert/Delete
#https://megamorf.gitlab.io/cheat-sheets/powershell-psreadline/

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




# This example will replace any aliases on the command line with the resolved commands.
Set-PSReadLineKeyHandler -Key "Alt+%" `
	-BriefDescription ExpandAliases `
	-LongDescription "Replace all aliases with the full command" `
	-ScriptBlock {
	param($key, $arg)

	$ast = $null
	$tokens = $null
	$errors = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

	$startAdjustment = 0
	foreach ($token in $tokens) {
		Write-Verbose "$token | $($token.TokenFlags)"
		if ($token.TokenFlags -band [TokenFlags]::CommandName) {
			
			$alias = $ExecutionContext.InvokeCommand.GetCommand($token.Extent.Text, 'Alias')
			if ($alias -ne $null) {
				$resolvedCommand = $alias.ResolvedCommandName
				if ($resolvedCommand -ne $null) {
					$extent = $token.Extent
					$length = $extent.EndOffset - $extent.StartOffset
					[Microsoft.PowerShell.PSConsoleReadLine]::Replace(
						$extent.StartOffset + $startAdjustment,
						$length,
						$resolvedCommand)

					# Our copy of the tokens won't have been updated, so we need to
					# adjust by the difference in length
					$startAdjustment += ($resolvedCommand.Length - $length)
				}

			}
		}
		<# else {
			$a = Get-Alias $token -ErrorAction Ignore
			if ($a) {
				$extent = $token.Extent
				$length = $extent.EndOffset - $extent.StartOffset
				[Microsoft.PowerShell.PSConsoleReadLine]::Replace(
					$extent.StartOffset + $startAdjustment,
					$length,
					$resolvedCommand)
			}
		} #>
	}
}


#endregion

$global:LoadTime = (Get-Date -Format $QDateFormat)

# region 

# region 

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
	param ($commandName, $wordToComplete, $cursorPosition)
	dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
	[Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
	$Local:word = $wordToComplete.Replace('"', '""')
	$Local:ast = $commandAst.ToString().Replace('"', '""')
	winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}

# endregion

# Invoke-Expression "$(thefuck --alias)"

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

# tdl completion powershell | Out-String | Invoke-Expression

#New-Item -ItemType SymbolicLink -Target .\Microsoft.PowerShell_profile.ps1 -Force .\Microsoft.VSCode_profile.ps1
# endregion

# Import-Module "$(get-item ((Find-Item gsudo)[0])|^ -exp Directory)\gsudoModule.psd1"
# Get-Command gsudoModule.psd1

function Get-ScoopPath {
	return "$($(Get-Item $(Get-Command scoop.ps1).Path).Directory.Parent.FullName)"
}

@(
	"$(Get-ScoopPath)\modules\scoop-completion",
	$(Get-Command gsudoModule.psd1).Path,
	"$(Get-ScoopPath)\apps\vcpkg\current\scripts\posh-vcpkg",
	$(Get-Module Terminal-Icons)
) | ForEach-Object { Import-Module $_ }

$gsudoLoadProfile = $true
$InVS2022 = $env:VSAPPIDNAME -eq 'devenv.exe'
$InVSCode = $env:TERM_PROGRAM -eq 'vscode'

if ($InVS2022) {
	Write-Verbose "In VS2022 terminal"
}
if ($InVSCode) {
	Write-Verbose "In VSCode terminal"
}

Write-Debug "$LoadTime | gsudo: $gsudoLoadProfile"

Set-Alias ffmpeg ffmpeg.exe
Set-Alias ffprobe ffprobe.exe
Set-Alias ffplay ffplay.exe

#C:\Users\Deci\deci.omp.json
#(@(& 'C:/Users/Deci/scoop/apps/oh-my-posh/current/oh-my-posh.exe' init pwsh --config='' --print) -join "`n") | Invoke-Expression