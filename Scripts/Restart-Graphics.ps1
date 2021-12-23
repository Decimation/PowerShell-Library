#Requires -Module PSKantan

Import-WinModule PnpDevice

if (!(IsAdmin)) {
	gsudo
	return
}

$d = Get-PnpDevice | where {
	$_.class -like "Display*"
}

$d | Disable-PnpDevice -Confirm:$false

$d | Enable-PnpDevice -Confirm:$false