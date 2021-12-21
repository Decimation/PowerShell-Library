<#	
	.NOTES
	===========================================================================
	 Created on:   	12/21/2021 4:37 PM
	 Created by:   	Deci
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>


$ds = Get-Date -Format 'MM-dd-yy'

mkdir "$ds"
cd $ds

pip list | Out-File "pip_$ds.txt"
scoop export | Out-File "scoop_$ds.txt"

winget export "winget_$ds.json" --include-versions
choco export "choco_$ds.config" --include-version-numbers

gci $env:ProgramFiles | Out-File "programs_$ds.txt"
gci ${env:ProgramFiles(x86)} | Out-File "programs86_$ds.txt"

if ((Get-Command -Name Invoke-WinCommand)) {
	Invoke-WinCommand {
		param ($arg0)
		Get-AppxPackage | Out-File "apps_$arg0.txt"
	} -ArgumentList $ds
	
	Invoke-WinCommand {
		param ($arg0)
		Export-StartLayout "startlayout_$arg0.txt"
	} -ArgumentList $ds
}