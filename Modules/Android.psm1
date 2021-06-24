

function Send-File {
	param (
		[Parameter(Mandatory=$true)][string]$src,
		[Parameter(Mandatory=$false)][string]$dest
	)

	if (!($dest)) {
		$dest = "sdcard/"
	}

	adb push $src $dest
}

function Remove-RemoteFile {
	param (
		[Parameter(Mandatory=$true)][string]$src
	)

	adb shell rm $src
}

function Send-All {
	param(
        [Parameter(Mandatory=$false)][string]$dest
    )
	
	$cd = Get-Location

	if (!($dest)) {
		$dest = "sdcard/"
	}

	#$dest = $(If ($args.Count -eq 0) {"sdcard/"} Else {$dest})

	Write-Host $cd files to $dest

	Get-ChildItem | ForEach-Object {
		if ([System.IO.File]::Exists($_)) {
			adb push $_ $dest
		}
	}
}

function Get-All {
	param (
		[Parameter(Mandatory=$true)][string]$src,
		[Parameter(Mandatory=$true)][string]$f
	)
	foreach ($x in (adb shell ls $src | Select-String $f)) {
		adb pull "$src/$x"
	}
}

function Get-RemoteFileSize {
	param (
		[Parameter(Mandatory=$true)][string]$src
	)
	return (adb shell wc -c $src) -Split " " | Select-Object -Index 0
}

function Get-RemoteItems {
	param (
		[Parameter(Mandatory=$true)][string]$src
	)
	return (adb shell ls $src) -Split "`n"
}

function Send-Tap {
	param (
		[Parameter(Mandatory=$true)][long]$x,
		[Parameter(Mandatory=$true)][long]$y
	)
	adb shell input tap $x $y
}


Set-Alias -Name sf -Value Send-File