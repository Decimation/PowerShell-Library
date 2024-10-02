function Get-NewShuffledNames {
	param($x)
	$y = [int[]]([System.Linq.Enumerable]::Range(0, $x.Length) | Get-Random -Count $x.Length)
	$yy = [System.Collections.Generic.Stack[int]]::new($y)
	$newNames = @()
	$x | ForEach-Object { 
		$newName = @{
			Item     = $_
			Original = $null
			New      = $null
			NewItem  = $null
		}
		$spl = $newName.Item.FullName.Split('_')
		$ext = $spl[-1].Split('.')
		$f = [int]($ext[0])
		$newName.Original = $f
		$newName.New = $yy.Pop()


		$newf = "shuffled_{0:0000}.$($ext[1])" -f $newName.New
		$newName.NewItem = Join-Path -Path $newName.Item.DirectoryName -ChildPath $newf
		$newNames += $newName
	}


	return $newNames
}

function Get-ShuffledNames {
	param (
		$NewNames
	)
	$NewNames | ForEach-Object { 
		Move-Item $_.Item $_.NewItem 
	}
}
#ffmpeg -i ..\yup.mp4 -vf "fps=30" frame_%04d.png
#ffmpeg -r 30 -i shuffled_%04d.png -c:v libx264 -vf "fps=30,format=yuv420p" output_video.mp4