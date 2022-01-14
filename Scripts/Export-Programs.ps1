<#	
	.NOTES
	===========================================================================
	 Created on:   	12/21/2021 4:37 PM
	 Created by:   	Deci
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

#Requires -Module PSKantan
$ds = "($(Get-Date -Format 'MM-dd-yy @ HH\hmm\mss\s'))"

$oldCd = gl
mkdir "$ds"
cd $ds

<# pip #>

Write-Host "Export: pip"
pip list | Out-File "pip.txt"

<# scoop #>

Write-Host "Export: scoop"
scoop export | Out-File "scoop.txt"

<# winget #>

Write-Host "Export: winget"
winget export "winget.json" --include-versions | Out-Null

<# choco #>

Write-Host "Export: choco"
choco export "choco.config" --include-version-numbers | Out-Null

<# Program Files & Program Files (x86) #>

Write-Host "Export: Program Files"
Write-Host "Export: Program Files (x86)"

gci $env:ProgramFiles | Out-File "programs.txt"
gci ${env:ProgramFiles(x86)} | Out-File "programs (x86).txt"

<# Appx & Start layout #>

if ((Get-Command -Name Invoke-WinCommand)) {
	Invoke-WinCommand {
		param ($arg0)
		Get-AppxPackage | Out-File "apps.txt"
	} -ArgumentList $ds
	Write-Host "Export: Appx"
	
	Invoke-WinCommand {
		param ($arg0)
		Export-StartLayout "start layout.xml"
	} -ArgumentList $ds
	Write-Host "Export: Start layout"
	
}

<# Environment variables #>

$lm = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
$cu = Get-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Environment"

Write-Host "Export: Environment variables (machine)"
Write-Host "Export: Environment variables (user)"

$lm | Out-File "env variables (machine).txt"
$cu | Out-File "env variables (user).txt"

<# pacman #>

if ((Get-Command -Name pacman)) {
	
	Write-Host "Export: pacman"
	pacman -Q | Out-File "pacman.txt"
	
}

Write-Host "Export: npm"
npm list -g | Out-File "npm.txt"

Write-Host ">> $ds" -ForegroundColor Green
cd $oldCd