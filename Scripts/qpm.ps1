#param($op, $op2)

[string]$op_search = 'search'
[string]$op_install = 'install'
[string]$op_uninstall = 'uninstall'
[string]$op_update = 'update'
[string]$op_list = 'list'



class PackageManager {
	[string]$name
	[string]$search
	[string]$install
	[string]$uninstall
	[string]$update
	[string]$list
	

	[void]Clear() {
		$this.GetType().GetFields()

	}
	
}


$DefaultPackageManager = [PackageManager] @{
	search    = $op_search
	install   = $op_install
	uninstall = $op_uninstall
	update    = $op_update
	list      = $op_list
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
		name = 'Get-AppxPackage'
	},
	[PackageManager]@{
		name   = 'pip'
		update = (($op_install + ' --upgrade'))
	}
)


$sxx = [string]::new('-', $([console]::BufferWidth))


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
if (-not $args) {
	return
}
Write-Debug "$($args -join ',')"
Get-PMJobs @args