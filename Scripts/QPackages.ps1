#Requires -Module PSKantan

$PackageManagers = @('scoop', 'winget')

function Search-Q {
	param (
		$Value
	)
	
	$jobs = @()
	for ($i = 0; $i -lt $PackageManagers.Count; $i++) {
		<# Action that will repeat until the condition is met #>
		$pm = $PackageManagers[$i]
		$j = Start-Job -ScriptBlock {
			& $using:pm $using:Value
		} -Name "[search] $pm"
		$jobs += $j
	}


	foreach ($j in $jobs) {
		$o = Receive-Job $j -Wait
		Write-Host "$o"
	}

}