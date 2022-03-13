<#	
	.NOTES
	===========================================================================
	 Created on:   	12/21/2021 4:37 PM
	 Created by:   	Deci
	===========================================================================
#>

#Requires -Module PSKantan
$ds = "($(Get-Date -Format 'MM-dd-yy @ HH\hmm\mss\s'))"

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

$Index = @(
	[PackageManager]@{
		name = 'scoop'
		run  = { 
			Write-Debug "$($args -join ',')"
			$dir = $args[0]
			scoop export | Out-File "$dir\scoop.txt"
		}
	},
	[PackageManager]@{
		name    = 'pacman'
		search  = '-Q'
		install = '-S'
		run     = {
			$dir = $args[0]

			if ((Get-Command -Name pacman)) {
				pacman -Q | Out-File "$dir\pacman.txt"
			}
		}
	},
	[PackageManager]@{
		name = 'choco'
		run  = {
			$dir = $args[0]

			choco export "$dir\choco.config" --include-version-numbers | Out-Null
		}
	},
	[PackageManager]@{
		name   = 'pip'
		update = (($pm_install + ' --upgrade'))
		run    = {
			$dir = $args[0]

			pip list | Out-File "$dir\pip.txt"
		}
	},
	[PackageManager]@{
		name = 'npm'
		run  = {
			$dir = $args[0]

			npm list -g | Out-File "$dir\npm.txt"
		}
	},
	[PackageManager]@{
		name = 'winget'
		run  = {
			$dir = $args[0]

			winget export "$dir\winget.json" --include-versions | Out-Null
		}
	},
	[BackupSource]@{
		name = 'appx'
		run  = {
			$dir = $args[0]

			if ((Get-Command -Name Invoke-WinCommand)) {
				Invoke-WinCommand {
					param ($arg0)
					Get-AppxPackage | Out-File "$dir\apps.txt"
				} -ArgumentList $ds
		
		
				Invoke-WinCommand {
					param ($arg0)
					
					Export-StartLayout "$dir\start layout.xml"
				} -ArgumentList $ds
			}
		}
	},
	[BackupSource]@{
		name = 'bd'
		run  = {
			$dir = $args[0]

			$bd = "$env:APPDATA\BetterDiscord"
			if ((Test-Path $bd)) {
				mkdir "$dir\BetterDiscord" | Out-Null
				Get-ChildItem "$bd\plugins" | Out-File "$dir\BetterDiscord\BetterDiscord plugins list.txt"
				robocopy "$bd\data\stable" '.' | Out-Null
			}
		}
	},
	[BackupSource]@{
		name = 'env'
		run  = {
			$dir = $args[0]
			
			$lm = Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
			$cu = Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment'
	
			$lm | Out-File "$dir\env variables (machine).txt"
			$cu | Out-File "$dir\env variables (user).txt"
		}
	}
	[BackupSource]@{
		name = 'progfiles'
		run  = {
			$dir = $args[0]
			Get-ChildItem $env:ProgramFiles | Out-File "$dir\programs.txt"
			Get-ChildItem ${env:ProgramFiles(x86)} | Out-File "$dir\programs (x86).txt"
		}
	}
)


Write-Debug "$($args -join ',')"

switch ($args[0]) {
	'run' {
		$n = $args[1]
		$op = $Index | Where-Object { $_.name -match $n }
		foreach ($a in $op) {

			if (-not (Test-Path $ds)) {
				mkdir $ds
			}
			
			Write-Host ">> $ds"
			Write-Host "$($a.name)"
			& $a.run $ds
		}
	}
	
	Default {
		$Index | ForEach-Object { 
			$_.name
		} | Format-Table
	}
}
