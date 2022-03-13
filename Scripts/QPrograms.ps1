<#	
	.NOTES
	===========================================================================
	 Created on:   	12/21/2021 4:37 PM
	 Created by:   	Deci
	===========================================================================
#>

#Requires -Module PSKantan
$ds = "($(Get-Date -Format 'MM-dd-yy @ HH\hmm\mss\s'))"

[string]$pm_search = 'search'
[string]$pm_install = 'install'
[string]$pm_uninstall = 'uninstall'
[string]$pm_update = 'update'
[string]$pm_list = 'list'

class BackupSource {
	[string]$name
	[scriptblock]$run
}

class PackageManager : BackupSource {
	
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
	search    = $pm_search
	install   = $pm_install
	uninstall = $pm_uninstall
	update    = $pm_update
	list      = $pm_list
}

$PackageManagers = @(
	[PackageManager]@{
		name = 'scoop'
		run  = { 
			scoop export | Out-File 'scoop.txt'

		}
	},
	[PackageManager]@{
		name    = 'pacman'
		search  = '-Q'
		install = '-S'
		run     = {
			if ((Get-Command -Name pacman)) {
		
				Write-Host 'Export: pacman'
				pacman -Q | Out-File 'pacman.txt'
		
			}
		}
	},
	[PackageManager]@{
		name = 'choco'
		run  = {
			choco export 'choco.config' --include-version-numbers | Out-Null

		}
	},
	[PackageManager]@{
		name   = 'pip'
		update = (($pm_install + ' --upgrade'))
		run    = {
			pip list | Out-File 'pip.txt'
			
		}
	},
	[PackageManager]@{
		name = 'npm'
		run  = {
			npm list -g | Out-File 'npm.txt'

		}
	},
	[PackageManager]@{
		name = 'winget'
		run  = {
			winget export 'winget.json' --include-versions | Out-Null

		}
	},
	[src]@{
		name = 'appx'
		run  = {
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
	},
	[src]@{
		name = 'bd'
		run  = {
			$bd = "$env:APPDATA\BetterDiscord"
			if ((Test-Path $bd)) {
				mkdir 'BetterDiscord' | Out-Null
				Get-ChildItem "$bd\plugins" | Out-File 'BetterDiscord plugins list.txt'
				robocopy "$bd\data\stable" '.' | Out-Null
			}
		}
	},
	[src]@{
		name = 'env'
		run  = {
			$lm = Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
			$cu = Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment'
	
			Write-Host 'Export: Environment variables (machine)'
			Write-Host 'Export: Environment variables (user)'
	
			$lm | Out-File 'env variables (machine).txt'
			$cu | Out-File 'env variables (user).txt'
		}
	}
	[src]@{
		name = 'progfiles'
		run  = {
			Get-ChildItem $env:ProgramFiles | Out-File 'programs.txt'
			Get-ChildItem ${env:ProgramFiles(x86)} | Out-File 'programs (x86).txt'
		}
	}
)


Write-Debug "$($args -join ',')"

switch ($args[0]) {
	'run' {
		$n = $args[1]
		$op = $PackageManagers | Where-Object { $_.name -eq $n }
		Write-Debug "$($op.name)"
		& $op.run
	}
	Default {
		$PackageManagers | ForEach-Object { 
			$_.name
		} | Format-Table
	}
}
