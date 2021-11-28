<#
# Profile
#>

#region [Modules]

$global:ModulePathRoot = "$Home\Documents\PowerShell\Modules\"
$global:ScriptPathRoot = "$Home\Documents\PowerShell\Scripts\"

$LocalScripts = (Get-ChildItem $global:ScriptPathRoot) | Where-Object {
	[System.IO.File]::Exists($_)
} | ForEach-Object {
	$_.ToString()
}

#https://github.com/WantStuff/AudioDeviceCmdlets
Import-Module "$ModulePathRoot\AudioDeviceCmdlets.dll"

function Import-LocalScript {
	param ($x)
	. "$global:ScriptPathRoot\$x"
}

function Import-LocalScripts {
	foreach ($x in $LocalScripts) {
		. "$x"
	}
}

function Update-LocalModules {
	Remove-Module PSKantan
	Import-Module -DisableNameChecking PSKantan
	Write-Debug "[$env:USERNAME] Updated modules"
}

Import-Module -DisableNameChecking PSKantan

#endregion

$script:CallerVariableModule = {
	# https://stackoverflow.com/questions/46528262/is-there-any-way-for-a-powershell-module-to-get-at-its-callers-scope
	
	New-Module {
		function Get-CallerVariable {
			param ([Parameter(Position = 1)]
				[string]$Name)
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

#region Configuration

$script:fr = 'ulm'
$script:qr = ".`$PROFILE; $fr"

$global:Downloads = "$env:USERPROFILE\Downloads\"

$InformationPreference = 'Continue'
$DebugPreference = 'Continue'

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'
$OutputEncoding = [System.Text.Encoding]::UTF8

#Set-Location $env:USERPROFILE\Downloads\

#endregion

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


#Write-Debug 'Imported miscellaneous'
#. "$ScriptPathRoot\Miscellaneous.ps1"

$script:LoadTime = (Get-Date -Format 'HH:mm:ss')

Write-Debug "[$env:USERNAME] Loaded profile ($LoadTime)"