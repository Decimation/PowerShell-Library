#Requires -Module PSKantan

$PackageManagers = @(
	@{
		name   = 'scoop'
		search = 'search'
	},
	@{
		name   = 'winget'
		search = 'search'
	},
	@{
		name   = 'choco'
		search = 'search'
	},
	@{
		name   = 'pacman'
		search = '-Q'
	}
)

function Search-Q {
	param (
		$Value
	)

	$jobs = @()

	for ($i = 0; $i -lt $PackageManagers.Count; $i++) {
		$pm = $PackageManagers[$i]
		$pmn = $pm.name
		$in = @($pm.search, $Value)
		Write-Debug "[$pmn] $UNI_ARROW_LEFT $in"
		$j = Start-Job -ScriptBlock {
			& $using:pmn @using:in
		} -Name "[$($in[0])] $pm"
		$jobs += $j
	}


	
	return $jobs
}

function Receive-Q {
	param (
		$jobs
	)
	foreach ($j in $jobs) {
		Receive-Job -Job $j -Wait
	}
}