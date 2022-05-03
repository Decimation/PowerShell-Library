
function Get-NetResource {
	param (
		$u
	)

	# $pp = $ProgressPreference
	# $ProgressPreference = 'SilentlyContinue'

	#Progress bars mess up ANSI virtual terminal sequences and output

	$r = Invoke-WebRequest $u
	
	# Clear-Host

	($f = New-TemporaryFile) | Out-Null

	# Write-Host "$f"

	$s = $r.Content[0..255]
	
	[System.IO.File]::WriteAllBytes($f.FullName, $s)

	$rr = file $($f.FullName)

	$ht = @{
		Response = $r
		TempFile = $f
		Results  = @($rr -as 'string')
	}


	# Clear-Host
	
	# $ProgressPreference = $pp

	return $ht
}