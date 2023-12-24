#Requires -Modules Microsoft.PowerShell.ConsoleGuiTools
using namespace Terminal.Gui

function Find-TerminalGuiDll {
	[OutputType([string])]
	param()

	$m = Get-Module -Name 'Microsoft.PowerShell.ConsoleGuiTools'
	
	if ($m -eq $null) {
		throw "Microsoft.PowerShell.ConsoleGuiTools module not found"
	}

	$i = Get-ChildItem -Path $(Resolve-Path "$($m.Path)\..") -Filter 'Terminal.Gui.dll'	
	$p = Resolve-Path $i
	return $p
}

Add-Type -Path $(Find-TerminalGuiDll)

function New-TGApplication {

	return [Terminal.Gui.Application]::new()
}



[Terminal.Gui.TableView]::new([System.Collections.Generic.List[object]]::new([object[]]@(
	[object[]]@('Name', 'Value'),
	[object[]]@('Name', 'Value'),
	[object[]]@('Name', 'Value')
)))