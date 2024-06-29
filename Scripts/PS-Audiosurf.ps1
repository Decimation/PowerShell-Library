

<#
.DESCRIPTION
	Detects the song name from an Audiosurf 2 replay file.
#>
function Get-SongName {
	param (
		[Parameter(Mandatory = $true)]
		$Path,
		$Seek = 15,
		[switch]$DeleteTmp
	)

	
	$hsh = Get-Random
	$TmpFile = "Frame_$hsh.png"


	Write-Verbose "Temp file 1: $TmpFile"

	$ff = ffmpeg -ss $Seek -i "$Path" -vf "select=eq(n\,34),crop=x=680:y=1045:w=860:h=35" -vframes 1 `
		-f image2pipe "$TmpFile" -y *>&1

	Write-Debug "$ff"

	$ocr = tesseract -l eng "$TmpFile" stdout 2>nul
	$name = ($ocr -is [array] ? $ocr[-1] : $ocr) -replace '\s+', ' '
	
	$res = @{
		Input = $Path
		Song  = $name
	}


	<# $p = Start-Process -FilePath $TmpFile -PassThru
	Start-Sleep -Seconds 1
	$p.Kill()
	$p.Dispose() #>
	# Start-Process $TmpFile -Wait
	if ($DeleteTmp) {
		Remove-Item -Path $TmpFile -ErrorAction SilentlyContinue
	}


	# Write-Host "$outStr"
	# return $name

	return $res
}


function Get-SongNames {
	param (
		$Paths

	)
	
	$i = 0
	$jobs = @()
	$Paths | ForEach-Object {
		$Path = $_

		Write-Debug "$Path"
		# $Path = Resolve-Path -Path $Path
		$job = Start-Job -Name "as_$i" -ScriptBlock ${function:Get-SongName} -ArgumentList $Path
		$i++
		$jobs += $job
	}


	$j = 0
	while ($j2 = Wait-Job -Any -Name "as_*") {
		
		$j2 | Receive-Job -AutoRemoveJob -Wait
		Write-Progress -Activity "Processing" -Status "Received" -PercentComplete ($j++ / $i) `
			-CurrentOperation "$output"
	
	}

}

