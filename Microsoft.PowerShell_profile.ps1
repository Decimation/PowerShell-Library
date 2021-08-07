<#
# Profile
#>


#region [Modules]

$DeciModules = @{
	Utilities   =	"$Home\Documents\PowerShell\Modules\Utilities.psm1";
	Android     =	"$Home\Documents\PowerShell\Modules\Android.psm1";
}


<#
.Description
Loads Deci modules
#>
function Import-Deci {
    
	foreach ($x in $DeciModules.Values) {
		Import-Module $x
	}
}


<#
.Description
Unloads Deci modules
#>
function Remove-Deci {
	foreach ($x in $DeciModules.Keys) {
		Remove-Module $x
	}
}

Import-Deci

const DeciName = 'Deci'

<#
.Description
Reloads Deci modules
#>
function Update-Deci {
	Remove-Deci
	Import-Deci
	Write-Debug "[$DeciName] Updated modules"
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


$script:qr = ".`$PROFILE; ud"

$script:DeciLoadTime = (Get-Date -Format 'HH:mm:ss')

Write-Debug "[$DeciName] Loaded profile ($DeciLoadTime)"

$global:Downloads = "$env:USERPROFILE\Downloads\"


# region Configuration

$InformationPreference = 'Continue'
$DebugPreference = 'Continue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'
#$PSDefaultParameterValues['Out-File:Encoding'] = [System.Text.Encoding]::GetEncoding(437)
#$OutputEncoding = [System.Text.Encoding]::GetEncoding(437)
#$OutputEncoding = 'utf8'
$OutputEncoding = [System.Text.Encoding]::UTF8

#Set-Location $env:USERPROFILE\Downloads\

# endregion

#region [Aliases]


Set-Alias -Name wh -Value Write-Host
Set-Alias -Name wd -Value Write-Debug

Set-Alias -Name so -Value Select-Object
Set-Alias -Name ss -Value Select-String

Set-Alias -Name ud -Value Update-Deci

#endregion
