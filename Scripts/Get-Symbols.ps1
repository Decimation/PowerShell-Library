function Get-Symbols {
	param (
		[Parameter(Mandatory = $true)][string]$s,
		[Parameter(Mandatory = $false)][string]$dest
	)

	if (!($dest) -or ( $dest -eq '.')) {
		$dest = Get-Location
	}
	
	symchk "$s" /s SRV*$dest*http://msdl.microsoft.com/download/symbols

	
	
	$p = [System.IO.Path]::GetFileNameWithoutExtension($s)
	# Rename-Item "$p.pdb" "$p-1"
	Move-Item "$p.pdb" "$p-1"
	Move-Item $(Get-ChildItem $(Get-ChildItem "$p-1")) .
	Remove-Item "$p-1" -Recurse
	Remove-Item pingme.txt

}