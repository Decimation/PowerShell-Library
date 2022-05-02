#Requires -Module PSKantan, AudioDeviceCmdlets

[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	$Names,

	[Parameter(Mandatory = $false)]
	$Types = @('Playback'),

	[switch]
	$MultimediaDefault
)

Write-Debug "$($Names -join ',')"

function Get-DefaultAudioDevice {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		$Types = '*'
	)

	return Get-AudioDevices | Where-Object { 
		$_.MultimediaDefault -and $_.Type -like $Types
	}
}
function Get-AudioDeviceName {
	param (
		[AudioDeviceCmdlets.AudioDevice]	$d
	)
	return $d.Name.Substring(0, $d.Name.LastIndexOf('(')).Trim()
}

function Get-AudioDevices {
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		$Names,
		
		[Parameter(Mandatory = $false)]
		$Types = @('Playback')
	)

	$devices = Get-AudioDevice -List

	$devices2 = $devices | Where-Object { 
		$name2 = Get-AudioDeviceName $_
		# $_.Type -eq 'Playback' -and 
		$Types -contains $_.Type -and
		$Names -contains $name2
	}

	return $devices2
}

$m = Get-AudioDevices -Names $Names

$cur = Get-AudioDevice | Where-Object { 
	$_.MultimediaDefault -eq $MultimediaDefault
}

# $m
Write-Host "Current: $($cur.Name)"

$Next = $null

for ($i = 0; $i -lt $m.Count; $i++) {
	if ((Get-AudioDeviceName $m[$i]) -like (Get-AudioDeviceName $cur[0])) {
		$Next = $m[$i + 1]
		break
	}
}

$Next = $Next ?? $m[0]

Write-Host "Next: $($Next.Name)"

Set-AudioDevice -MultimediaDefault -Index $Next.Index