
function Get-SongName {
	param (
		$Path,
		$Seek = 15
	)


	<# $tmp = [System.IO.Path]::GetTempFileName()
	$tmp = [System.IO.Path]::ChangeExtension($tmp, 'png')
	$tmp2 = [System.IO.Path]::GetTempFileName()
	$tmp2 = [System.IO.Path]::ChangeExtension($tmp2, 'png') #>
	
	$hsh = $Path.GetHashCode()
	$tmp = "Frame_$hsh.png"

	Write-Verbose "Temp file 1: $tmp | Temp file 2: $tmp2"

	$ff = ffmpeg -ss $Seek -i "$Path" -vf "select=eq(n\,34),crop=x=870:y=1050:w=680:h=50" -vframes 1 -f image2pipe "$tmp" -y *>&1
	$name = tesseract -l eng "$tmp" stdout 2>nul

	$name = $name -is [array] ? $name[-1] : $name
	$name = $name.Trim()
	$name = $name -replace '\s+', ' '

	$outStr = @(
		$PSStyle.Foreground.Cyan, $Path, $PSStyle.Reset,
		"→",
		$PSStyle.Foreground.Green, $name, $PSStyle.Reset
	)

	Write-Host "$outStr"

	return $name
	<# $ff2 = ffmpeg -i "$tmp" -vf "crop=x=870:y=1050:w=680:h=50" -y "$tmp2" *>&1
	$name = tesseract -l eng "$tmp2" stdout
	$name = $name -is [array] ? $name[-1] : $name
	$name = $name.Trim()
	$name = $name -replace '\s+', ' '
	
	# Remove-Item $tmp
	# Remove-Item $tmp2

	$outStr = @(
		$PSStyle.Foreground.Cyan, $Path, $PSStyle.Reset,
		"→",
		$PSStyle.Foreground.Green, $name, $PSStyle.Reset
	)

	Write-Host "$outStr"

	return $name #>

}
