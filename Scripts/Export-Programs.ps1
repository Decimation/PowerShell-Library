<#	
	.NOTES
	===========================================================================
	 Created on:   	12/21/2021 4:37 PM
	 Created by:   	Deci
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>


$ds = "($(Get-Date -Format 'MM-dd-yy @ HH\hmm\mss\s'))"

mkdir "$ds"
cd $ds

<# pip #>

pip list | Out-File "pip.txt"

<# scoop #>

scoop export | Out-File "scoop.txt"

<# winget #>

winget export "winget.json" --include-versions | Out-Null

<# choco #>

choco export "choco.config" --include-version-numbers | Out-Null

<# Program Files & Program Files (x86) #>

gci $env:ProgramFiles | Out-File "programs.txt"
gci ${env:ProgramFiles(x86)} | Out-File "programs (x86).txt"

<# Appx & Start layout #>

if ((Get-Command -Name Invoke-WinCommand)) {
	Invoke-WinCommand {
		param ($arg0)
		Get-AppxPackage | Out-File "apps.txt"
	} -ArgumentList $ds
	
	Invoke-WinCommand {
		param ($arg0)
		Export-StartLayout "start layout.xml"
	} -ArgumentList $ds
}

<# Environment variables #>

$lm = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
$cu = Get-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Environment"

$lm | Out-File "env variables (machine).txt"
$cu | Out-File "env variables (user).txt"

<# pacman #>

if ((Get-Command -Name pacman)) {
	pacman -Q | Out-File "pacman.txt"
}