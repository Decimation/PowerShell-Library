# $DebugPreference = "SilentlyContinue"
# $ErrorActionPreference = 'Break'

Write-Host "this will report all modules with duplicate (older and newer) versions installed"
Write-Host "be sure to run this as an admin" -ForegroundColor yellow
Write-Host "(You can update all your Azure RMmodules with update-module Azurerm -force)"

$mods = Get-InstalledModule -Debug:$false


foreach ($mod in $mods) {
	Write-Host "Checking $($mod.name)"
	# $latest = Get-InstalledModule $mod.name
	
	$specificmods = Get-InstalledModule -Name $mod.Name -AllVersions -Debug:$false `
	| Sort-Object -Descending -Property Version

	$modInfo = @{
		Module = $mod
		Latest = $specificmods | Select-Object -First 1
		Older  = $null
	}

	if ($specificmods.Count -gt 1) {
		$modInfo.Older = $specificmods | Select-Object -Skip 1
	}
	else {
		$modInfo.Older = $specificmods.Latest
	}

	$modInfo | Format-Table `
	@{Label = "Module Name"; Expression = { $_.Module.Name } }, `
	@{Label = "Module Version"; Expression = { $_.Module.Version } }, `
	@{Label = "Latest Version"; Expression = { $_.Latest.Version } }, `
	@{Label = "Older Version"; Expression = { $_.Older.Version } } -AutoSize `
	| Out-Host
}

Write-Host "done"