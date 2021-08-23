function ConvertTo-Gif {
	param (
		[Parameter(Mandatory = $true)][string]$x,
		[Parameter(Mandatory = $true)][string]$y
	)
	
	#ffmpeg -i <input> -vf “fps=25,scale=1920:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse” <output gif>

	ffmpeg -i $x -vf 'fps=25,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse' $y
}

function Get-ItemInfo {
	param (
		[switch] $m
	)

	Write-Host (Get-CenteredString 'ffprobe') -ForegroundColor Yellow
	ffprobe -hide_banner -show_streams -select_streams a $args
	
	Write-Host $script:SEPARATOR

	if ($m) {
		
		Write-Host (Get-CenteredString 'magick') -ForegroundColor Yellow
		magick identify $args
	}
}




function Get-Clip {
	param (
		[Parameter(Mandatory = $true)][string]$f,
		[Parameter(Mandatory = $true)][string]$a,
		[Parameter(Mandatory = $true)][string]$b,
		[Parameter(Mandatory = $false)][string]$o

	)

	$d = Get-TimeDurationString $a $b

	$f2 = [System.IO.Path]::GetFileNameWithoutExtension($f)
	
	if (!($o)) {
		#$o = [System.IO.Path]::Combine($dir,"$f2 @ $d.mp4")
		#$o = [System.IO.Path]::Combine("$f2 @ $d.mp4")
		$o = "$f2-edit.mp4"
	}

	Write-Debug $o
	
	return (ffmpeg -ss $a -i $f -t $d $o)
}

Set-Alias -Name gii -Value Get-ItemInfo
