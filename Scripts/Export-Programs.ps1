<#	
	.NOTES
	===========================================================================
	 Created on:   	12/21/2021 4:37 PM
	 Created by:   	Deci
	===========================================================================
#>

#Requires -Module PSKantan
$ds = "($(Get-Date -Format 'MM-dd-yy @ HH\hmm\mss\s'))"

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

