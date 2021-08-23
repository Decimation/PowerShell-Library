
<#
# Android utilities
#>

#region [IO]


function AdbShell {
	return (adb shell $args)
}

function AdbSend {
	param (
		[Parameter(Mandatory = $true)][string]$src,
		[Parameter(Mandatory = $false)][string]$dest
	)

	if (!($dest)) {
		$dest = 'sdcard/'
	}

	(adb push $src $dest)
}


function AdbSendAll {
	param(
		[Parameter(Mandatory = $false)][string]$dest
	)
	
	$cd = Get-Location

	if (!($dest)) {
		$dest = 'sdcard/'
	}

	Write-Host $cd files to $dest
	
	Get-ChildItem | ForEach-Object {
		if ([System.IO.File]::Exists($_)) {
			(adb push $_ $dest)
		}
	}
}


<#
.Description

#>
function AdbSyncItems {
	param (
		[Parameter(Mandatory = $true)][string]$remote,
		[Parameter(Mandatory = $false)][string]$local,
		
		[Parameter(Mandatory = $true)]
		[ValidateSet('Remote', 'Local')]
		$Direction
	)


	#$remoteItems | ?{($localItems -notcontains $_)}

	#| sed "s/ /' '/g"
	#https://stackoverflow.com/questions/45041320/adb-shell-input-text-with-space

	$localItems = Get-ChildItem -Name
	$remoteItems = AdbItemsList $remote
	$remote = AdbEscape $remote [EscapeType]::Exchange

	#wh $remote

	if ($Direction -eq 'Remote') {
		$m = Get-Difference $remoteItems $localItems

		foreach ($x in $m) {
			(adb push $x $remote)
		}
	}
	elseif ($Direction -eq 'Local') {
		$m = Get-Difference $localItems $remoteItems

		foreach ($x in $m) {
			(adb pull "$remote/$x")
		}
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

	foreach ($x in ((AdbItemsList $src) | Select-String -Pattern $filter)) {
		(adb pull "$src/$x")
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

	(adb shell rm $src)
}

<#
.Description
Gets size of file
#>
function AdbFileSize {
	param (
		[Parameter(Mandatory = $true)][string]$src
	)
	
	return (adb shell wc -c $src) -Split ' ' | Select-Object -Index 0
}

<#
.Description
Lists directory content
#>
function AdbItemsList {
	param (
		[Parameter(Mandatory = $true)][string]$src
	)

	$src = AdbEscape $src [EscapeType]::Shell
	$x = (adb shell ls $src)

	return ($x) -Split "`n"
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
function AdbSendTap {
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
			$x3 = New-Object -TypeName System.Collections.Generic.List[string]
		
			foreach ($b in $x2) { 
				if ($b.Contains(' ')) {
					$b2 = "`"$b/`""
				}
				else {
					$b2 = $b
				}
				$x3.Add($b2)
			}
		
			return [string]::Join('/', $x3).TrimEnd('/')
		}
		Default {}
	}

	
}

#region [Variables]

$global:RD_SD = 'sdcard/'
$global:RD_PIC = $RD_SD + 'Pictures/'
$global:RD_VID = $RD_SD + 'Videos/'
$global:RD_DL = $RD_SD + 'Download/'
$global:RD_DOC = $RD_SD + 'Documents/'

$script:AdbCommands = @('push', 'pull', 'connect', 'disconnect', 'tcpip', 
	'start-server', 'kill-server', 'shell', 'usb', 'devices')

#endregion

Register-ArgumentCompleter -Native -CommandName adb -ScriptBlock  {
	param($wordToComplete, $commandAst, $fakeBoundParameters)

	$script:AdbCommands | Where-Object {
		$_ -like "$wordToComplete*"
	} | ForEach-Object {
		"$_"
	}
}