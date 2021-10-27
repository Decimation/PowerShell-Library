<#
# Profile
#>

#region [Modules]

$global:ScriptPathRoot = "$Home\Documents\PowerShell\Scripts\"
$LocalScripts = (Get-ChildItem $global:ScriptPathRoot) | Where-Object { [System.IO.File]::Exists($_) } | ForEach-Object { $_.ToString() }

function Import-LocalScript {
	param($x)
	. "$global:ScriptPathRoot\$x"
}

function Import-LocalScripts {
	foreach ($x in $LocalScripts) {
		. "$x"
	}
}

function Update-LocalModules {
	Remove-Module PSKantan
	Import-Module PSKantan
	Write-Debug "[$env:USERNAME] Updated modules"
}

Import-Module PSKantan

#endregion

$script:CallerVariableModule = {
	# https://stackoverflow.com/questions/46528262/is-there-any-way-for-a-powershell-module-to-get-at-its-callers-scope

	New-Module {
		function Get-CallerVariable {
			param([Parameter(Position = 1)][string]$Name)
			$PSCmdlet.SessionState.PSVariable.GetValue($Name)
		}
		function Set-CallerVariable {
			param(
				[Parameter(ValueFromPipeline)][string]$Value,
				[Parameter(Position = 1)]$Name
			)
			process { $PSCmdlet.SessionState.PSVariable.Set($Name, $Value) }
		}
	} | Import-Module
}


function Prompt {
	#Write-Host ('PS ' + "[$(Get-Date -Format 'HH:mm:ss')] " + $(Get-Location) + '>') -NoNewline

	$C1 = [System.ConsoleColor]::Green
	$C2 = [System.ConsoleColor]::Blue

	Write-Host 'PS ' -NoNewline -ForegroundColor $C2
	$dll = $(Get-Date -Format 'HH:mm:ss')
	Write-Host ("[$dll] ") -NoNewline -ForegroundColor $C1
	Write-Host "$(Get-Location)" -NoNewline
	Write-Host '>' -NoNewline

	return ' '
}

#region [Aliases]

Set-Alias -Name wh -Value Write-Host
Set-Alias -Name wd -Value Write-Debug

Set-Alias -Name so -Value Select-Object
Set-Alias -Name ss -Value Select-String

Set-Alias -Name ulm -Value Update-LocalModules

Set-Alias -Name ie -Value Invoke-Expression

#endregion

# region Configuration

$script:fr = 'ulm'
$script:qr = ".`$PROFILE; $fr"

$script:LoadTime = (Get-Date -Format 'HH:mm:ss')

Write-Debug "[$env:USERNAME] Loaded profile ($LoadTime)"

$global:Downloads = "$env:USERPROFILE\Downloads\"

$InformationPreference = 'Continue'
$DebugPreference = 'Continue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'
$OutputEncoding = [System.Text.Encoding]::UTF8

#Set-Location $env:USERPROFILE\Downloads\

# endregion

function New-PInvoke {
	param (
		$imports,
		$className, $dll, $returnType, $funcName, $funcParams
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

<#
.SYNOPSIS
  Runs the given script block and returns the execution duration.
  Discovered on StackOverflow. http://stackoverflow.com/questions/3513650/timing-a-commands-execution-in-powershell
  Adapted by Read Stanton

.EXAMPLE
  Measure-CommandEx { ping -n 1 google.com }
#>
function Measure-CommandEx ([ScriptBlock]$Expression, [int]$Samples = 1, [Switch]$Silent, [Switch]$Long) {

	$timings = @()
	do {
		$sw = New-Object Diagnostics.Stopwatch
		if ($Silent) {
			$sw.Start()
			$null = & $Expression
			$sw.Stop()
			Write-Host '.' -NoNewline
		}
		else {
			$sw.Start()
			& $Expression
			$sw.Stop()
		}
		$timings += $sw.Elapsed

		$Samples--
	}
	while ($Samples -gt 0)


	$stats = $timings | Measure-Object -Average -Minimum -Maximum -Property Ticks

	# Print the full timespan if the $Long switch was given.

	$dict = @{}

	if ($Long) {
		$dict = @{
			'Avg' = $((New-Object System.TimeSpan $stats.Average).ToString());
			'Min' = $((New-Object System.TimeSpan $stats.Minimum).ToString());
			'Max' = $((New-Object System.TimeSpan $stats.Maximum).ToString());
		}
	}
	else {
		$dict = @{
			'Avg' = "$((New-Object System.TimeSpan $stats.Average).TotalMilliseconds.ToString()) ms";
			'Min' = "$((New-Object System.TimeSpan $stats.Minimum).TotalMilliseconds.ToString()) ms";
			'Max' = "$((New-Object System.TimeSpan $stats.Maximum).TotalMilliseconds.ToString()) ms";
		}
	}

	return $dict

}

Set-Alias time Measure-CommandEx

. "$ScriptPathRoot\Miscellaneous.ps1"