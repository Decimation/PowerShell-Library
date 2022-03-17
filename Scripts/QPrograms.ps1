[CmdletBinding()]
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
			# Write-Debug "$($args -join ',')"
			$dir = $args[0]
			scoop export | Out-File "$dir\scoop.txt" | Out-Null
		}
	},
	[PackageManager]@{
		name    = 'pacman'
		search  = '-Q'
		install = '-S'
		list    = $this.search
		export  = {
			$dir = $args[0]

			pacman -Q | Out-File "$dir\pacman.txt" | Out-Null
			
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

			pip list | Out-File "$dir\pip.txt" | Out-Null
		}
	},
	[PackageManager]@{
		name   = 'npm'
		export = {
			$dir = $args[0]

			npm list -g | Out-File "$dir\npm.txt" | Out-Null
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
	}, [BackupSource]@{
		name   = 'wt'
		export = {
			$dir = $args[0]
			Copy-Item "C:\Users\Deci\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" `
				"$dir\$($name)_settings.json"
		}
	}, [BackupSource]@{
		name   = "vscode"
		export = {
			$dir = $args[0]
			
			Copy-Item "C:\Users\Deci\AppData\Roaming\Code\User\settings.json" `
				"$dir\$($name)_settings.json"
		}
	}
)

# endregion


$IndexSelected = $Index | Where-Object { $_.name -match $n }
$OutputFolder = "($(Get-Date -Format 'MM-dd-yy @ HH\hmm\mss\s'))"

if (-not (Test-Path $OutputFolder)) {
	mkdir $OutputFolder
}

Write-Host "$($IndexSelected|Select-Object -ExpandProperty name)"
Write-Debug "$op | $query |$n"

Read-Host 

switch ($op) {
	'export' {
		
		

		$l = $IndexSelected.Length
		
		for ($i = 0; $i -lt $l; $i++) {
			$val = $IndexSelected[$i]
			Write-Debug "$($val.name)"
			& $val.export $OutputFolder
			
			$sz = [string]::Format('{0:00}/{1:00}', $i + 1, $l)
			Write-Host "`r$sz" -NoNewline
			
			# Write-Progress -Id 1 -Activity Updating -Status 'Progress' -PercentComplete (($i / $l) * 100.0)
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
