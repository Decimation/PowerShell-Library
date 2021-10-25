


function ConvertTo-Extension {

	param($items, $ext)

	#Get-ChildItem *.ogg

	$items | ForEach-Object {
		$x = [System.IO.Path]::GetFileNameWithoutExtension($_) + $ext
		$y = [System.IO.Path]::GetDirectoryName($_)

		ffmpeg.exe -i $_ ($y + '\' + $x)
	}
}


function Get-ConcatVideo {
	param (
		$x,
		$f,
		$o
	)

	$x | ForEach-Object {
		Add-Content -Value "file '$_'" -Path $f
	}

	ffmpeg.exe -f concat -safe 0 -i $f -c copy $o

	Remove-Item $f
}

