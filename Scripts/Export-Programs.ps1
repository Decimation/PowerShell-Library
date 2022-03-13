<#	
	.NOTES
	===========================================================================
	 Created on:   	12/21/2021 4:37 PM
	 Created by:   	Deci
	===========================================================================
#>

#Requires -Module PSKantan
$ds = "($(Get-Date -Format 'MM-dd-yy @ HH\hmm\mss\s'))"
#region

$script:export_pip = {
	<# pip #>
	
	Write-Host 'Export: pip'
	pip list | Out-File 'pip.txt'
}

$script:export_scoop = {
	<# scoop #>
	
	Write-Host 'Export: scoop'
	scoop export | Out-File 'scoop.txt'
}

$script:export_winget = {
	<# winget #>
	
	Write-Host 'Export: winget'
	winget export 'winget.json' --include-versions | Out-Null
}


$script:export_choco = {
	<# choco #>
	
	Write-Host 'Export: choco'
	choco export 'choco.config' --include-version-numbers | Out-Null
}

$script:xport_progfiles = {
	
	<# Program Files & Program Files (x86) #>
	
	Write-Host 'Export: Program Files'
	Write-Host 'Export: Program Files (x86)'
	
	Get-ChildItem $env:ProgramFiles | Out-File 'programs.txt'
	Get-ChildItem ${env:ProgramFiles(x86)} | Out-File 'programs (x86).txt'
}

$script:export_appx = {
	<# Appx & Start layout #>
	
	if ((Get-Command -Name Invoke-WinCommand)) {
		Invoke-WinCommand {
			param ($arg0)
			Get-AppxPackage | Out-File 'apps.txt'
		} -ArgumentList $ds
		
		Write-Host 'Export: Appx'
		
		Invoke-WinCommand {
			param ($arg0)
			Export-StartLayout 'start layout.xml'
		} -ArgumentList $ds
		Write-Host 'Export: Start layout'
		
	}
}

$script:export_env = {
	<# Environment variables #>
	
	$lm = Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
	$cu = Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment'
	
	Write-Host 'Export: Environment variables (machine)'
	Write-Host 'Export: Environment variables (user)'
	
	$lm | Out-File 'env variables (machine).txt'
	$cu | Out-File 'env variables (user).txt'
}

$script:export_pacman = {
	<# pacman #>
	
	if ((Get-Command -Name pacman)) {
		
		Write-Host 'Export: pacman'
		pacman -Q | Out-File 'pacman.txt'
		
	}
	
}

$script:export_npm = {
	<# npm #>
	
	Write-Host 'Export: npm'
	npm list -g | Out-File 'npm.txt'
}

$global:export_bd = {
	<# BetterDiscord #>
	
	$bd = "$env:APPDATA\BetterDiscord"
	if ((Test-Path $bd)) {
		mkdir 'BetterDiscord' | Out-Null
		Get-ChildItem "$bd\plugins" | Out-File 'BetterDiscord plugins list.txt'
		robocopy "$bd\data\stable" '.' | Out-Null
	}
}



if ($args[0] -eq 'run') {
	Write-Host ">> $ds" -ForegroundColor Green
	mkdir $ds | Out-Null
	Set-Location $ds
	
	Get-Variable -Name 'export*' | ForEach-Object {
		& $_.Value
	}
	#Set-Location $oldCd
}

#endregion


#region New

#param($op, $op2)



<#

######################################################################################################

#>


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
	list	  = $op_list
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
		$op,
		$op2,
		$qw = $true,
		$k = $true
	)
	
	$jobs = @()
	Remove-Job 'j_*' -Force
	
	for ($i = 0; $i -lt $PackageManagers.Length; $i++) {
		$pm = $PackageManagers[$i]
		$splat = @()
		
		switch ($op) {
			'search' {
				$splat += ($pm.search)
			}
			Default {
			}
		}
		$splat += $op2
		$job = Start-Job -Name "j_$($pm.name)" -ScriptBlock {
			param ([PackageManager]$pm1,
				$splat1)
			
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
	} else {
		return $jobs
	}
	
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

#endregion New