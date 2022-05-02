#Requires -Module PSKantan, AudioDeviceCmdlets

param([string[]] $cycle)
Write-Debug "$cycle"
function Get-DefaultAudioDevice {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		$types = '*'
	)

	return Get-AudioDevice | Where-Object { 
		$_.MultimediaDefault -and $_.Type -like $types
	}
}

$devices = Get-AudioDevice
$devices2 = (Get-AudioDevice -List | Where-Object { $_.Type -eq 'Playback' } | Where-Object { $_.Name -match $cycle })
$devices2
$m = @()

foreach ($d in $devices) {
	if ($cycle -contains $d.Name ) {
		$m += $d
		Write-Host "$($d.Name)"
	}
}

Write-Host "$($d -join ',') | $($d.Name)"

foreach ($i in $cycle) {
	
}