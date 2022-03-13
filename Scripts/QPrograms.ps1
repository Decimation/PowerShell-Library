﻿[CmdletBinding()]
param(
	[parameter(Mandatory = $true)]$op, 
	[parameter(Mandatory = $false)]$query,
	[parameter(Mandatory = $false)]$n = '.' 
)


<#	
	.NOTES
	===========================================================================
	 Created on:   	12/21/2021 4:37 PM
	 Created by:   	Deci
	===========================================================================
#>

#Requires -Module PSKantan


# region 
class BackupSource {
	[string]$name
	[scriptblock]$export
}

class PackageManager : BackupSource {
	
	[string]$search = 'search'
	[string]$install = 'install'
	[string]$uninstall = 'uninstall'
	[string]$update = 'update'
	[string]$list = 'list'
	
	
}
# endregion

# region 

$Index = @(
	[PackageManager]@{
		name   = 'scoop'
		export = { 
			Write-Debug "$($args -join ',')"
			$dir = $args[0]
			scoop export | Out-File "$dir\scoop.txt"
		}
	},
	[PackageManager]@{
		name    = 'pacman'
		search  = '-Q'
		install = '-S'
		list    = $this.search
		export  = {
			$dir = $args[0]

			if ((Get-Command -Name pacman)) {
				pacman -Q | Out-File "$dir\pacman.txt"
			}
		}
	},
	[PackageManager]@{
		name   = 'choco'
		export = {
			$dir = $args[0]

			choco export "$dir\choco.config" --include-version-numbers | Out-Null
		}
	},
	[PackageManager]@{
		name   = 'pip'
		update = (($pm_install + ' --upgrade'))
		export = {
			$dir = $args[0]

			pip list | Out-File "$dir\pip.txt"
		}
	},
	[PackageManager]@{
		name   = 'npm'
		export = {
			$dir = $args[0]

			npm list -g | Out-File "$dir\npm.txt"
		}
	},
	[PackageManager]@{
		name   = 'winget'
		export = {
			$dir = $args[0]

			winget export "$dir\winget.json" --include-versions | Out-Null
		}
	},
	[BackupSource]@{
		name   = 'appx'
		export = {
			$dir = $args[0]

			if ((Get-Command -Name Invoke-WinCommand)) {
				Invoke-WinCommand {
					param ($arg0)
					Get-AppxPackage | Out-File "$dir\apps.txt"
				} -ArgumentList $OutputFolder
		
		
				Invoke-WinCommand {
					param ($arg0)
					
					Export-StartLayout "$dir\start layout.xml"
				} -ArgumentList $OutputFolder
			}
		}
	},
	[BackupSource]@{
		name   = 'bd'
		export = {
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
		name   = 'env_vars'
		export = {
			$dir = $args[0]
			
			$lm = Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
			$cu = Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment'
	
			$lm | Out-File "$dir\env variables (machine).txt"
			$cu | Out-File "$dir\env variables (user).txt"
		}
	}
	[BackupSource]@{
		name   = 'progfiles'
		export = {
			$dir = $args[0]
			Get-ChildItem $env:ProgramFiles | Out-File "$dir\programs.txt"
			Get-ChildItem ${env:ProgramFiles(x86)} | Out-File "$dir\programs (x86).txt"
		}
	}
)

# endregion


$IndexSelected = $Index | Where-Object { $_.name -match $n }
$OutputFolder = "($(Get-Date -Format 'MM-dd-yy @ HH\hmm\mss\s'))"


switch ($op) {
	'export' {
		
		foreach ($a in $IndexSelected) {

			if (-not (Test-Path $OutputFolder)) {
				mkdir $OutputFolder
			}

			Write-Host ">> $OutputFolder"
			Write-Host "$($a.name)"
			& $a.export $OutputFolder
		}
	}
	Default {
		$f = $op
		foreach ($e in $IndexSelected) {
			$v = @($e.$f, $query)
			
			if (-not (Test-Command $e.name)) {
				continue;
			}
		
			Write-Host ">> $($e.name)" -ForegroundColor Green
			& $e.name @v
		}
	}

	'help' {
		$Index | ForEach-Object { 
			$_.name
		} | Format-Table
	}
}