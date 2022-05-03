<#
.DESCRIPTION
Cycles through audio devices
.PARAMETER Names

.NOTES


#>

#Requires -Module PSKantan, AudioDeviceCmdlets, Pansies

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

function Get-AudioDeviceName {
	param (
		[AudioDeviceCmdlets.AudioDevice]$d
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

$Devices = Get-AudioDevices -Names $Names

$CurrentDevice = Get-AudioDevice | Where-Object { 
	$_.MultimediaDefault -eq $MultimediaDefault
}

# $Devices

Write-Host "$(Text "Current:" -ForegroundColor 'Orange') $(Text $CurrentDevice.Name -ForegroundColor 'Cyan')"

$Next = $null

for ($i = 0; $i -lt $Devices.Count; $i++) {
	if ((Get-AudioDeviceName $Devices[$i]) -like (Get-AudioDeviceName $CurrentDevice[0])) {
		$Next = $Devices[$i + 1]
		break
	}
}

$Next = $Next ?? $Devices[0]

Write-Host "$(Text "Next:" -ForegroundColor 'Orange') $(Text $Next.Name -ForegroundColor 'LawnGreen')"

$Next = Set-AudioDevice -MultimediaDefault -Index $Next.Index

return $Next