
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
	
	
	$argC = $input.Count
	$argList = $input
	$cmd = $argList[0]
	
	switch ($cmd) {
		'push' {
			if ($Path) {
				process {
					$src = $Path
				}
			} else {
				$src = $argList[1]
			}
			$src = Adb-Escape $src Shell
			
			$argList[1] = $src
			if ($argC -lt 3) {
				$dest = $AdbRemoteOutputDefault
			} else {
				$dest = $argList[2]
			}
			
			#$dest = $dest.Replace(' ', "`\ ")
			#$dest = Adb-Escape $dest Shell
			
			#$argList += $dest
			
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
	
	#return (adb.exe $argList)
	adb.exe $argList
	
}


#region ADB completion

$script:AdbCommands = @(
	'push', 'pull', 'connect', 'disconnect', 'tcpip',
	'start-server', 'kill-server', 'shell', 'usb',
	'devices', 'install', 'uninstall'
	#todo...
)

Register-ArgumentCompleter -Native -CommandName adb -ScriptBlock {
	param ($wordToComplete,
		$commandAst,
		$fakeBoundParameters)
	
	$script:AdbCommands | Where-Object {
		$_ -like "$wordToComplete*"
	} | ForEach-Object {
		"$_"
	}
}


#endregion

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


enum AdbDestination {
	Remote
	Local
}

enum Direction {
	Up
	Down
}

function Adb-InputFastSwipe {
	param (
		[Parameter(Mandatory = $false)]
		[Direction]$d,
		[Parameter(Mandatory = $false)]
		[int]$t,
		[Parameter(Mandatory = $false)]
		[int]$c
	)
	
	if (!($t)) {
		$t = 25
	}
	if (!($d)) {
		$d = [Direction]::Down
	}
	
	while ($c-- -gt 0) {
		switch ($d) {
			Down {
				adb shell input swipe 500 1000 300 300 $t
			}
			Up {
				adb shell input swipe 300 300 500 1000 $t
			}
		}
		Start-Sleep -Milliseconds $t
	}
}

function Adb-SyncItems {
	param (
		[Parameter(Mandatory = $true)]
		[string]$remote,
		[Parameter(Mandatory = $false)]
		[string]$local,
		[Parameter(Mandatory = $true)]
		[AdbDestination]$d
	)
	
	#$remoteItems | ?{($localItems -notcontains $_)}
	
	#| sed "s/ /' '/g"
	#https://stackoverflow.com/questions/45041320/adb-shell-input-text-with-space
	
	$localItems = Get-ChildItem -Name
	$remoteItems = Adb-GetItems $remote
	$remote = Adb-Escape $remote Exchange
	
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
		Default {
		}
	}
	return $m
}

<#
.Description
Deletes file
#>
function Adb-RemoveItem {
	param (
		[Parameter(Mandatory = $true)]
		[string]$src
	)
	
	(adb shell rm "$src")
}


<#
.Description
Lists directory content
#>
function Adb-GetItems {
	param (
		[Parameter(Mandatory = $true)]
		[string]$src,
		[Parameter(Mandatory = $false)]
		[string]$filter,
		[switch]$relative
		
	)
	
	$src = Adb-Escape $src Shell
	$x = (adb shell ls $src)
	
	$files = ($x) -Split "`n"
	
	if (!$relative) {
		for ($i = 0; $i -lt $files.Count; $i++) {
			$files[$i] = [System.IO.Path]::Combine($src, $files[$i]).Replace('\ ', ' ').Replace('\', '/')
		}
	}
	if ($filter) {
		$files = $files | Select-String -Pattern $filter
	}
	return $files
}

#endregion


function Adb-GetItem {
	param ($x)
	
	<#$s = "Dir"
	$y = (adb shell "if [ -d $x ]; then echo $s; fi")
	if ($y) {
		$t = $y.Trim() -eq $s
	}#>
	
	<#$s2 = "File"
	$y2 = (adb shell "if [ -f $x ]; then echo $s2; fi")#>
	
	$isDir = $false
	$isFile = $false
	$rg = [string[]] (adb shell wc -c $x 2>&1)
	$s1 = $rg[0]
	$size = -1
	
	[array]::Sort($rg)
	
	if ($rg.Length -ge 2) {
		$isDir = $rg[1].Contains("Is a directory")
	} elseif ($s1.Contains("No such")) {
		#...
	} else {
		$isFile = $true
		$size = [int]$s1.Split(' ')[0]
	}
	
	
	$buf = @{
		IsFile	    = $isFile
		IsDirectory = $isDir
		Size	    = $size
	}
	
	
	return $buf
}

function Adb-GetPackages {
	return ((adb shell pm list packages -f) -split '`n')
}

<#function Adb-EnablePackage {
	param (
		[Parameter(Mandatory = $true)]
		[long]$x
	)
	
	(adb shell pm enable $x)
}#>


enum EscapeType {
	Shell
	Exchange
}

function Adb-Escape {
	param (
		[Parameter(Mandatory = $true)]
		[string]$x,
		[Parameter(Mandatory = $true)]
		[EscapeType]$e
	)
	
	switch ($e) {
		Shell {
			$x = $x.Replace('`', [string]::Empty)
			#$x = $x.Replace(' ', '\ ')
			
			return $x
		}
		Exchange {
			$x2 = $x.Split('/')
			$x3 = New-List 'string'
			
			foreach ($b in $x2) {
				if ($b.Contains(' ')) {
					$b2 = "`"$b/`""
				} else {
					$b2 = $b
				}
				$x3.Add($b2)
			}
			return PathJoin($x3, '/')
		}
		Default {
		}
	}
}