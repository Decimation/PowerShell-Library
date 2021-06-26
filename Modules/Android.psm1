

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


function Send-All {
	param(
        [Parameter(Mandatory=$false)][string]$dest
    )
	
	$cd = Get-Location

	if (!($dest)) {
		$dest = "sdcard/"
	}


	Write-Host $cd files to $dest

	Get-ChildItem | ForEach-Object {
		if ([System.IO.File]::Exists($_)) {
			adb push $_ $dest
		}
	}
}

function Get-File {
	param (
		[Parameter(Mandatory=$true)][string]$src,
		[Parameter(Mandatory=$false)][string]$dest
	)

	if (!($dest)) {
		$dest = (Get-Location)
	}

	adb pull $src $dest
}

function Get-Files {
	param (
		[Parameter(Mandatory=$true, Position=0)][string]$src,
		[Parameter(Mandatory=$false, ParameterSetName="Filter")][string]$filter
	)

	if (!($filter)) {
		$filter = "(.*?)"
	}

	foreach ($x in ((Get-RemoteItems $src) | Select-String -Pattern $filter)) {
		adb pull "$src/$x"
	}
}


function Remove-RemoteFile {
	param (
		[Parameter(Mandatory=$true)][string]$src
	)

	adb shell rm $src
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

#region

Set-Alias -Name sf -Value Send-File

#endregion
