

function qtest {
	$c = Get-PSCallStack
	Write-Debug "$($c.Arguments)"
	
}