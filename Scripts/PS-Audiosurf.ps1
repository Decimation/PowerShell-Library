

<#
.DESCRIPTION
	Detects the song name from an Audiosurf 2 replay file.
#>
function Get-SongName {
	param (
		[Parameter(Mandatory = $true)]
		$Path,
		$Seek = 15
	)

	$hsh = $Path.GetHashCode()
	$TmpFile = "Frame_$hsh.png"


	Write-Verbose "Temp file 1: $TmpFile"

	$ff = ffmpeg -ss $Seek -i "$Path" -vf "select=eq(n\,34),crop=x=870:y=1050:w=1000:h=50" -vframes 1 -f image2pipe `
		"$TmpFile" -y *>&1

	$ocr = tesseract -l eng "$TmpFile" stdout 2>nul

	$name = ($ocr -is [array] ? $ocr[-1] : $ocr) -replace '\s+', ' '
	
	<# $outStr = @(
		$PSStyle.Foreground.Cyan, "Input: $Path", $PSStyle.Reset,
		"→",
		$PSStyle.Foreground.Green, "OCR: $name", $PSStyle.Reset
	) #>

	$res = @{
		Input = $Path
		Song  = $name
	}

	Remove-Item -Path $TmpFile -ErrorAction SilentlyContinue

	# Write-Host "$outStr"
	# return $name

	return $res
}


function Get-SongNames {
	param (
		$Names
	)
	
	$i = 0
	$Names | ForEach-Object {
		$Path = $_
		$job = Start-Job -Name "as_$i" -ScriptBlock ${function:Get-SongName} -ArgumentList $Path
		$i++
	}

	<# 
	$jobs | ForEach-Object {
		$job = $_
		$job | Wait-Job
		$job | Receive-Job
	} #>

	<# while ($jobs.State -contains "Running") {
		Start-Sleep -Milliseconds 100

	} #>

	while ($j2 = Wait-Job -Any -Name "as_*") {
		
		$j2 | Receive-Job -AutoRemoveJob -Wait
		
	}

	# return $jobs
}

