
<#
# Android utilities
#>

$global:RD_SD = 'sdcard/'
$global:RD_PIC = $RD_SD + 'Pictures/'
$global:RD_VID = $RD_SD + 'Videos/'
$global:RD_DL = $RD_SD + 'Download/'
$global:RD_DOC = $RD_SD + 'Documents/'

$global:AdbRemoteOutputDefault = $RD_SD

<#
.Description
ADB enhanced passthru
#>
function adb {

	$argC = $args.Count
	$argList = $args

	$cmd = $argList[0]

	switch ($cmd) {
		'push' {
			$src = $argList[1]

			if ($argC -lt 3) {
				$dest = $AdbRemoteOutputDefault
			}

			$argList += $dest

			Write-Verbose "push $src -> $dest"
		}
		'pull' {

		}
		'shell' {

		}

		# todo ...

		Default {

		}
	}

	Write-Verbose "New args: $($argList -join ',')"

	adb.exe $argList
}


# region ADB completion

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

# endregion

#region [IO]

function script:EnsureRemoteOutput($dest) {

	#to-do: private

	if (!($dest)) {
		$dest = $global:AdbRemoteOutputDefault
	}

	$usingDefault = $dest -eq $global:AdbRemoteOutputDefault

	#Write-Debug "Output: $dest | Default: $global:AdbRemoteOutputDefault"

	if ($usingDefault) {
		Write-Debug "Using default remote output ($global:AdbRemoteOutputDefault)"
	}

	return $dest
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
Deletes file
#>
function AdbRemoveItem {
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
		[Parameter(Mandatory = $false)][string]$filter,
		[switch]$relative

	)

	$src = AdbEscape $src Shell
	$x = (adb shell ls $src)

	$files = ($x) -Split "`n"

	if (!$relative) {
		for ($i = 0; $i -lt $files.Count; $i++) {
			$files[$i] = [System.IO.Path]::Combine($src, $files[$i]).Replace('\', '/')
		}
	}
	if ($filter) {
		$files = $files | Select-String -Pattern $filter
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




