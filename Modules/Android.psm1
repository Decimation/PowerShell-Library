
<#
# Android utilities
#>

$global:RD_SD = 'sdcard/'
$global:RD_PIC = $RD_SD + 'Pictures/'
$global:RD_VID = $RD_SD + 'Videos/'
$global:RD_DL = $RD_SD + 'Download/'
$global:RD_DOC = $RD_SD + 'Documents/'

#region [IO]


function AdbShell {
	return (adb shell $args)
}

function AdbInputText {
	param($s)
	$s2 = $(AdbEscape -e shell $s)

	return (adb shell input text $s2)
}

function AdbPush {
	param (
		[Parameter(Mandatory = $true)][string]$src,
		[Parameter(Mandatory = $false)][string]$dest
	)

	if (!($dest)) {
		$dest = $global:RD_SD
	}

	(adb push $src $dest)
}


function AdbPushAll {
	param(
		[Parameter(Mandatory = $false)][string]$dest
	)
	
	$cd = Get-Location

	if (!($dest)) {
		$dest = $global:RD_SD
	}

	Write-Host $cd files to $dest
	
	Get-ChildItem | ForEach-Object {
		if ([System.IO.File]::Exists($_)) {
			(adb push $_ $dest)
		}
	}
}


enum Direction {
	Remote
	Local
}

function AdbSyncItems {
	param (
		[Parameter(Mandatory = $true)][string]$remote,
		[Parameter(Mandatory = $false)][string]$local,
		[Parameter(Mandatory = $true)][Direction]$d
	)

	#$remoteItems | ?{($localItems -notcontains $_)}

	#| sed "s/ /' '/g"
	#https://stackoverflow.com/questions/45041320/adb-shell-input-text-with-space

	$localItems = Get-ChildItem -Name
	$remoteItems = AdbListItems $remote
	$remote = AdbEscape $remote Exchange

	#wh $remote
	switch ($d) {
		Remote {
			$m = Get-Difference $remoteItems $localItems

			foreach ($x in $m) {
			(adb push $x $remote)
			}
		}
		Local {
			$m = Get-Difference $localItems $remoteItems

			foreach ($x in $m) {
			(adb pull "$remote/$x")
			}
		}
		Default {}
	}
	return $m
}

<#
.Description
Pulls file to destination folder (if specified)
#>
function AdbPull {
	param (
		[Parameter(Mandatory = $true)][string]$src,
		[Parameter(Mandatory = $false)][string]$dest
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
function AdbPullAll {
	param (
		[Parameter(Mandatory = $true, Position = 0)][string]$src,
		[Parameter(Mandatory = $false, ParameterSetName = 'Filter')][string]$filter
	)

	if (!($filter)) {
		$filter = '.'
	}

	foreach ($x in ((AdbListItems $src) | Select-String -Pattern $filter)) {
		(adb pull "$x")
	}
}

<#
.Description
Deletes file
#>
function AdbRemove {
	param (
		[Parameter(Mandatory = $true)][string]$src
	)

	(adb shell rm "$src")
}

<#
.Description
Gets size of file
#>
function AdbFileSize {
	param (
		[Parameter(Mandatory = $true)][string]$src
	)
	
	return (adb shell wc -c "$src") -Split ' ' | Select-Object -Index 0
}

<#
.Description
Lists directory content
#>
function AdbListItems {
	param (
		[Parameter(Mandatory = $true)][string]$src,
		[Parameter(Mandatory = $false)][bool]$relative

	)

	$src = AdbEscape $src Shell
	$x = (adb shell ls $src)

	$files = ($x) -Split "`n"

	if (!$relative) {
		for ($i = 0; $i -lt $files.Count; $i++) {
			$files[$i] = [System.IO.Path]::Combine($src, $files[$i]).Replace('\', '/')
		}
	}
	
	return $files
}

#endregion

function AdbListPackages {
	
	return ((adb shell pm list packages -f) -split '`n')
}

function AdbEnablePackage {
	param (
		[Parameter(Mandatory = $true)][long]$x
	)
	
	(adb shell pm enable $x)
}


<#
.Description
Sends input tap
#>
function AdbInputTap {
	param (
		[Parameter(Mandatory = $true)][long]$x,
		[Parameter(Mandatory = $true)][long]$y
	)
	(adb shell input tap $x $y)
}

enum EscapeType {
	Shell
	Exchange
}

function AdbEscape {
	param (
		[Parameter(Mandatory = $true)][string]$x,
		[Parameter(Mandatory = $true)][EscapeType]$e

	)

	switch ($e) {
		Shell {
			$x2 = $x.Replace(' ', "`\ ")
			return $x2
		}
		Exchange {
			$x2 = $x.Split('/')
			$x3 = New-List 'string'
		
			foreach ($b in $x2) { 
				if ($b.Contains(' ')) {
					$b2 = "`"$b/`""
				}
				else {
					$b2 = $b
				}
				$x3.Add($b2)
			}
		
			return PathJoin($x3, '/')
		}
		Default {}
	}

	
}


$script:AdbCommands = @('push', 'pull', 'connect', 'disconnect', 'tcpip', 
	'start-server', 'kill-server', 'shell', 'usb', 'devices', 'install', 'uninstall')

Register-ArgumentCompleter -Native -CommandName adb -ScriptBlock {
	param($wordToComplete, $commandAst, $fakeBoundParameters)

	$script:AdbCommands | Where-Object {
		$_ -like "$wordToComplete*"
	} | ForEach-Object {
		"$_"
	}
}