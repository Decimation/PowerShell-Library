

function Compress-Item {
	param (
		[Parameter(Mandatory = $true)]
		$f,
		[Parameter(Mandatory = $true)]
		$f2,
		[Parameter(Mandatory = $true)]
		$q
	)
	
	magick convert -filter Triangle -define filter:support=2 `
		   -unsharp 0.25x0.08+8.3+0.045 -dither None `
		   -posterize 136 -quality $q -define png:compression-filter=5 `
		   -define png:compression-level=9 `
		   -define png:compression-strategy=1 -define png:exclude-chunk=all `
		   -interlace none -colorspace sRGB $f $f2
}

function Get-ConcatVideo {
	param (
		$files,
		$listFile,
		$output
	)
	
	$files | ForEach-Object {
		Add-Content -Value "file '$_'" -Path $listFile
	}
	
	ffmpeg -f concat -safe 0 -i $listFile -c copy $output
	
	Remove-Item $listFile
}

function Get-Clip {
	param (
		[string]$i,
		[timespan]$start,
		[timespan]$end,
		[string]$o
	)
	
	$t = $end - $start
	$startStr = [string]$start
	$tStr = [string]$t
	
	ffmpeg -ss $startStr -i $i -t $tStr $o
}
