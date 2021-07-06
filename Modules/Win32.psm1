function Get-Symbols {
	param (
		[Parameter(Mandatory=$true)][string]$s,
		[Parameter(Mandatory=$false)][string]$dest
	)

	if (!($dest)) {
		$dest = Get-Location
	}
	
	symchk "$s" /s SRV*$dest*http://msdl.microsoft.com/download/symbols
}