
<#
# Android utilities
#>

<#----------------------------------------------------------------------------#>

<#
.Description
Sends file to device destination folder
#>
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

<#
.Description
Sends all files within current directory to device destination folder
#>
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
function Get-Missing {
	param (
		[Parameter(Mandatory=$true)][string]$remote,
		[Parameter(Mandatory=$false)][string]$local
	)

	#$a1 | ?{($a2 -notcontains $_)}


	#| sed "s/ /' '/g"
	#https://stackoverflow.com/questions/45041320/adb-shell-input-text-with-space

	$a2 = Get-ChildItem -Name

	$a1 = Get-RemoteItems $remote

	$m = $a2 | Where-Object{($a1 -notcontains $_)}

	<#foreach ($x in $m) {
		adb push $x $remote
	}#>

	return $m
}

<#
.Description
Pulls file to destination folder (if specified)
#>
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

<#
.Description
Pulls files from device folder that match filter (if specified)
#>
function Get-Files {
	param (
		[Parameter(Mandatory=$true, Position=0)][string]$src,
		[Parameter(Mandatory=$false, ParameterSetName="Filter")][string]$filter
	)

	if (!($filter)) {
		$filter = "."
	}

	foreach ($x in ((Get-RemoteItems $src) | Select-String -Pattern $filter)) {
		adb pull "$src/$x"
	}
}

<#
.Description
Deletes file
#>
function Remove-RemoteFile {
	param (
		[Parameter(Mandatory=$true)][string]$src
	)

	adb shell rm $src
}

<#
.Description
Gets size of file
#>
function Get-RemoteFileSize {
	param (
		[Parameter(Mandatory=$true)][string]$src
	)
	return (adb shell wc -c $src) -Split " " | Select-Object -Index 0
}

<#
.Description
Lists directory content
#>
function Get-RemoteItems {
	param (
		[Parameter(Mandatory=$true)][string]$src
	)
	
	$x=adb shell ls $src

	if (!($x) -or $x -contains "No such") {
		wd "Error"
		return $null
	}

	return ($x) -Split "`n"
}

function Get-ShellEscape {
	param (
		[Parameter(Mandatory=$true)][string]$v
	)
	$v5 = $v.Replace(" ", "`\ ")
	return $v5
}

function Get-ExchangeEscape {
	param (
		[Parameter(Mandatory=$true)][string]$v
	)

	$v3 = $v.Split("/")
	$v4 = New-Object -TypeName System.Collections.Generic.List[string]

	foreach ($b in $v3) { 
		if ($b.Contains(" ")) {
			$vx = "`"$b/`""
		} else {
			$vx = $b
		}
		$v4.Add($vx)
	}

	return [string]::Join("/", $v4).TrimEnd("/")
	
}

<#
.Description
Sends input tap
#>
function Send-Tap {
	param (
		[Parameter(Mandatory=$true)][long]$x,
		[Parameter(Mandatory=$true)][long]$y
	)
	adb shell input tap $x $y
}

<#----------------------------------------------------------------------------#>

Set-Alias -Name sf -Value Send-File
Set-Alias -Name gf -Value Get-File
