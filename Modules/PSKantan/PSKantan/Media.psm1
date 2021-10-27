

function Compress-Item {
	param (
		[Parameter(Mandatory = $true)]$f,
		[Parameter(Mandatory = $true)]$f2,
		[Parameter(Mandatory = $true)]$q
	)

	magick.exe convert -filter Triangle -define filter:support=2 -unsharp 0.25x0.08+8.3+0.045 -dither None `
		-posterize 136 -quality $q -define png:compression-filter=5 -define png:compression-level=9 `
		-define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB `
		$f $f2
}

function Get-ConcatVideo {
	param (
		$x, $f, $o
	)

	$x | ForEach-Object {
		Add-Content -Value "file '$_'" -Path $f
	}

	ffmpeg.exe -f concat -safe 0 -i $f -c copy $o

	Remove-Item $f
}

