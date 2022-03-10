#param($op, $op2)

class PackageManager {
	[string]$name
	[string]$search = 'search'
	[string]$install = 'install'
	[string]$uninstall = 'uninstall'
	[string]$update = 'update'
	[string]$list = 'list'
}

$PackageManagers = @(
	[PackageManager]@{
		name = 'scoop'
	},
	[PackageManager]@{
		name = 'winget'
	},
	[PackageManager]@{
		name    = 'pacman'
		search  = '-Q'
		install = '-S'
	},
	[PackageManager]@{
		name = 'choco'
	},
	[PackageManager]@{
		name = 'pip'
	}
)

<# function QPackageManage {
	[CmdletBinding()]

	param (
		$op, $op2
	)
	$rg = @()
	$jobs = Get-PMJobs $op $op2
	for ($i = 0; $i -lt $jobs.Length; $i++) {
		Write-Host "$($jobs[$i])"
		$r = Receive-Job -Job $jobs[$i] -Keep
		$rg += $r
	}
	return $rg
} #>

#function qs{ $args|%{receive-Job $_}}

#$jobs|%{Receive-Job $_ -Keep}

$sxx = [string]::new('-', $([console]::BufferWidth))

<# function QPackageManage {
	param($jobs)

	# $jobs | ForEach-Object {
	# 	$jj = $_
	# 	Write-Host "$sz`n>> $($jj.Name)" -ForegroundColor Green
		
	# 	# if ($r) {
	# 	# 	Wait-Job $_
	# 	# }

	# 	$jx = Receive-Job $jj -Keep:$keep -Wait:$r
	# 	if ($jx.State -eq 'Completed') {
	# 		$jobs.RemoveAt
	# 	}
	# }

	# while ($jobs | Where-Object { $_.State -ne 'Completed' }) { 
	# 	# QPackageManage $jobs $keep $r 
		
	# }

	# process {

	# 	$jobs | ForEach-Object -Parallel {
	# 		$res = Receive-Job -Job $_ -Wait -WriteJobInResults

	# 	}
	# }
} #>


function Get-PMJobs {
	[CmdletBinding()]
	param (
		$op, $op2, $qw = $true, $k = $true
	)

	$jobs = @()
	Remove-Job 'j_*' -Force

	for ($i = 0; $i -lt $PackageManagers.Length; $i++) {
		$pm = $PackageManagers[$i]
		$splat = @()

		switch ($op) {
			'search' { $splat += ($pm.search) }
			Default {}
		}
		$splat += $op2
		$job = Start-Job -Name "j_$($pm.name)" -ScriptBlock { 
			param([PackageManager]$pm1, $splat1) 
			
			#Write-Debug "$pm1 | $ox"
			& ($pm1.name) @splat1
		} -ArgumentList @($pm, $splat)

		$jobs += $job
		
	}

	$ids = [int[]]($jobs | Select-Object -ExpandProperty Id)
	
	Write-Debug "$($ids -join ',')"
	#Wait-Job $ids

	if ($qw) {

		$resr = @()
		$c = $true
		$jobs | ForEach-Object {
			# Write-Output "$($_)"
			$res = Receive-Job -Job $_ -Wait -WriteJobInResults 
			# $res = Receive-Job -Job $_ -Keep:$k
			Write-Debug "$($res)"

			# Write-Output "$($res)"
			#Write-Output "$res"
			$resr += $res
			
		}
		return $resr
	}
	else { return $jobs }
	
}

<# if ((!$op) -and !($op2)) {
	$op = 'search'
	$op2 = 'test'
} #>

Write-Debug "$($args -join ',')"
Get-PMJobs @args