<#
# Profile
#>

#region [Modules]

$global:ModulePathRoot = $env:PSModulePath.Split(';')[0]
$LocalModules = (Get-ChildItem $global:ModulePathRoot) | ForEach-Object { $_.ToString() }

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
function Import-LocalModule {
	param($x)
	Import-Module "$global:ModulePathRoot\$x" -DisableNameChecking
}

function Import-LocalModules {
	foreach ($x in $LocalModules) {
		Import-Module $x -DisableNameChecking
	}
}

function Remove-LocalModules {
	foreach ($x in $LocalModules) {
		Remove-Module $([System.IO.Path]::GetFileNameWithoutExtension($x))
	}
}

Import-LocalModules

function Update-LocalModules {
	Remove-LocalModules
	Import-LocalModules
	Write-Debug "[$env:USERNAME] Updated modules"
}


#endregion

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


function Prompt {
	Write-Host ('PS ' + "[$(Get-Date -Format 'HH:mm:ss')] " + $(Get-Location) + '>') -NoNewline
	return ' '
}

#region [Aliases]


Set-Alias -Name wh -Value Write-Host
Set-Alias -Name wd -Value Write-Debug

Set-Alias -Name so -Value Select-Object
Set-Alias -Name ss -Value Select-String

Set-Alias -Name ud -Value Update-LocalModules

Set-Alias -Name ie -Value Invoke-Expression

#endregion


# region Configuration

$script:qr = ".`$PROFILE; ud"

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
