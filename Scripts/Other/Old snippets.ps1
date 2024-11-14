
<# $global:CurCursor = 0
Set-PSReadlineKeyHandler -Key Alt+x -ScriptBlock {
	param($key, $arg)

	# Get the current command line
	$global:ast = $null
	$global:tokens = $null
	$global:errors = $null
	$global:cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

	# Find the innermost command token
	$innermostCommandToken = $tokens | Where-Object { $_.TokenFlags -band [TokenFlags]::CommandName } | Select-Object -Last 1

	$innermostCommand = $innermostCommandToken.Extent.Text

	# Write-Debug "$ast | $tokens | $errors | $cursor"
	# Get the current cursor position
	
	$cmd = Get-Command -Name $innermostCommand -ErrorAction SilentlyContinue

	if ($cmd) {
		$parameters = $cmd.Parameters.Keys
		$parameters = $parameters | Where-Object { $_ -notmatch '^-' }
		$parameters = $parameters | Sort-Object

		$selectedParameter = $parameters[0]
		$selectedParameter = $selectedParameter -replace '^(-[^:]+).*', '$1'
		$selectedParameter = $selectedParameter.Trim()

		# Replace the current token with the selected parameter
		$tokens[$innermostCommandToken.TokenIndex] = $selectedParameter

		# Update the command line with the modified tokens
		$newLine = $tokens -join ' '
		[Microsoft.PowerShell.PSConsoleReadLine]::Setc($newLine, $cursor + ($selectedParameter.Length - $innermostCommand.Length), $null)
		$global:CurCursor = $cursor + ($selectedParameter.Length - $innermostCommand.Length)
	}
	else {
		[Microsoft.PowerShell.PSConsoleReadLine]::Ding()
	}
	# Split the command line into tokens
	# $tokens = $line -split '\s+'
	# $command = ($tokens | Where-Object { $_.TokenFlags -like 'CommandName' })
	# $tok = ($tokens | Where-Object { $_.Text.Length -le $cursor })
	# $tokenIndex = [Math]::Max(0, [Array]::IndexOf($tokens, $tok))
	# $token = $tokens[$tokenIndex]
	# Write-Debug "$ast | $tokens | $errors | $cursor | $command | $tok"

}
#>
<# Set-PSReadLineKeyHandler -Chord 'Ctrl+\' -ScriptBlock {
	param($key, $arg)
	# [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(0)
	
	$ast = $null
	$tokens = $null
	$errors = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

	# Write-Debug "$ast | $tokens | $errors | $cursor"

	# Identify the token at the cursor position
	$selectedToken = $tokens | Where-Object { 
		
		($cursor -ge $_.Extent.StartOffset -and $cursor -le $_.Extent.EndOffset) `
			-and ($_.TokenFlags -band [TokenFlags]::CommandName)
	}

	# Select the token (highlight it, for example)
	# This is a placeholder action; you can customize what you want to do with the selected token
	if ($selectedToken -ne $null) {
		#Write-Host "Selected Token: $($selectedToken)" -ForegroundColor Cyan
	}
	
	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectedToken.Extent.StartOffset + $cursor)
	# $nextToken = $tokens | Where-Object { $_ -eq $selectedToken } | Select-Object -Skip 1 -First 1

    # # Move the cursor to the next token's start position
    # if ($nextToken -ne $null) {
    # }
} #>



<# Set-PSReadLineKeyHandler -Key "Alt+c" `
	-ScriptBlock {
	param($key, $arg)

	$ast = $null
	$tokens = $null
	$errors = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

	$startAdjustment = 0
	foreach ($token in $tokens) {
		# Write-Verbose "$token | $($token.TokenFlags)"
		if ($token.TokenFlags -band [TokenFlags]::CommandName) {
			$extent = $token.Extent
			
			$length = $extent.EndOffset - $extent.StartOffset

			[PSConsoleReadLine]::SetCursorPosition($token.Extent.StartOffset)
			[PSConsoleReadLine]::SelectForwardWord($null, $null)
			
			$l = $null
			$c = $null
			[PSConsoleReadLine]::GetBufferState([ref]$l, [ref]$c);
			
			if ($sz -ne $token.Text) {
				$s = $null
				$li = $null
				[PSConsoleReadLine]::GetSelectionState([ref]$s, [ref]$li)
				[PSConsoleReadLine]::SelectForwardWord($null, $null)
				$sz = $l[$s..$li]
				Write-Verbose "`n$length $c $l $s $li $sz"
				
			}


		}
	}
} #>

<# ,
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