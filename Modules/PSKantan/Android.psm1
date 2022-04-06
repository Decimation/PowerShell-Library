
<#
# Android utilities
#>


$global:RD_SD = 'sdcard/'

#region ADB completion

$script:AdbCommands = @(
	'push', 'pull', 'connect', 'disconnect', 'tcpip',
	'start-server', 'kill-server', 'shell', 'usb',
	'devices', 'install', 'uninstall'
	#todo...
)

Register-ArgumentCompleter -Native -CommandName adb -ScriptBlock {
	param (
		$wordToComplete,
		$commandAst,
		$fakeBoundParameters
	)
	
	$script:AdbCommands | Where-Object {
		$_ -like "$wordToComplete*"
	} | ForEach-Object {
		"$_"
	}
}


#endregion

#region [IO]

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
ADB enhanced passthru
#>
function adb {
	
	$argBuf = [System.Collections.Generic.List[string]]::new()
	$argBuf.AddRange([string[]]$args)
	
	Write-Verbose "Original args: $(Write-Quick $argBuf)`n"
	
	switch ($argBuf[0]) {
		'push' {
			if ($argBuf.Count -lt 3) {
				$argBuf += 'sdcard/'
			}
		}
		Default {
		}
	}
	
	Write-Verbose "Final args: $(Write-Quick $argBuf)"
	
	adb.exe @argBuf
}

function Adb-GetDevices {
	$d = (adb devices) -as [string[]]
	$d = $d[1..($d.Length)]
	return $d
}

function Adb-QPush {
	
	param (
		$f,
		[parameter(Mandatory = $false)]
		$d = 'sdcard/'
	)

	if ($f -is [array]) {
		$f | Invoke-Parallel -Parameter $d -ImportVariables -Quiet -ScriptBlock {
			adb push "$_" $parameter
		}
	}
	else {
		adb push $f $d
	}
	
}


$global:SyncState = [PSCustomObject]@{
	SyncTable = [hashtable]::Synchronized(
		@{
			c  = 0 
			l  = 0
			fc = 0
		}
	)
	d         = $null
}

function Adb-QPull {
	param(
		$r, 
		[parameter(Mandatory = $false)] 
		$d = $(Get-Location), 
		[switch]$retain
	)
	
	$d = Resolve-Path $d
	Write-Host "$d"
	Read-Host -Prompt "..."
	$r = Adb-GetItems $r -t 'f'
	
	

	$r | Invoke-Parallel -Parameter $d -ImportVariables -Quiet -ScriptBlock {
		
		$vx = adb pull $_ "$parameter"
		
		# $ss = Get-SubstringBetween -value $vx -a '(' -b ')'
		# $bc = $ss.Split(' ')[0] -as [int]

		# $sec = $s2.Split(' ')[3]

		# $sz = (Get-ChildItem $parameter).count
		$global:SyncState.SyncTable.fc++
		Write-Host "`r$($global:SyncState.SyncTable.fc)" -NoNewline

		# $SyncTable.c++
		# Write-Host "`r $($SyncTable.c)/$($SyncTable.l)" -NoNewline

		<# Write-Progress -Activity g -PercentComplete (($i / $l) * 100.0) #>
	}

	#todo
	
	Clear-SyncState
}

$global:SyncState = [PSCustomObject]@{
	SyncTable = [hashtable]::Synchronized(
		@{
			c  = 0 
			l  = 0
			fc = 0
		}
	)

	Output    = $null
}

function Clear-SyncState {
	
	$global:SyncState.SyncTable.fc = 0
	$global:SyncState.SyncTable.l = 0
	$global:SyncState.SyncTable.c = 0
	$global:SyncState.d = $null

	<# $global:SyncState = [PSCustomObject]@{
		SyncTable = [hashtable]::Synchronized(
			@{
				c  = 0 
				l  = 0
				fc = 0
			}
		)
		d  = $null
	} #>
}

function Adb-GetItems {
	[CmdletBinding()]
	[outputtype([string[]])]
	param (
		[Parameter()]
		$x,
		[Parameter(Mandatory = $false)]
		$t
	)
	
	$r = Adb-FindItems $x -type $t
	
	$r = [string[]] ($r | Sort-Object)

	if ($pattern) {
		$r = $r | Where-Object {
			$_ -match $pattern 
		}
	}
	
	return $r
}
function Adb-FindItems {
	[CmdletBinding()]
	[outputtype([string[]])]
	param (
		$x,
		[Parameter(Mandatory = $false)]
		$name,
		[parameter(Mandatory = $false)]
		$type
	)
	$a = @('shell', "find $x")
	if ($name) {
		$a += '-name', $name
	}
	if ($type) {
		
		$a += '-type', $type
	}
	
	$r = adb @a
	
	
	return $r
}
#endregion


function Adb-GetItem {
	param ($x,
		[Parameter(Mandatory = $false)]$SyncState
	)
	
	
	$a = @('shell', "wc -c $x", '2>&1')
	$x = adb @a
	$x = [string]$x
	Write-Debug "$x|$(typeof $x)"

	if ($x -match 'Is a directory') {
		$isDir = $true
		$isFile = $false
	}
	elseif ($x -match ('No such')) {
		#...
		return
	}
	else {
		$isDir = $false
		$isFile = $true
		$size = [int]$x.Split(' ')[0]
	}
	
	$buf = @{
		IsFile      = $isFile
		IsDirectory = $isDir
		Size        = $size
		Orig        = $x
	}
	
	

	return $buf
}

function Adb-GetPackages {
	$aa = @('shell', 'pm list packages -f')
	return (adb @aa)
}


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
			$SyncState = $x.Split('/')
			$x3 = New-List 'string'
			
			foreach ($b in $SyncState) {
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
		Default {
		}
	}
}

function Adb-HandleSettings {
	param (
		$Operation,	$Scope, $Name
	)

	return adb shell settings $Operation $Scope $Name @args
}

<# function Adb-GetAccessibility {
	[outputtype([string[]])]
	$s = Adb-HandleSettings 'get' 'secure' 'enabled_accessibility_services'

	$s2 = ($s -split '/') -as [string[]]
	return $s2
}

function Adb-AddAccessibility {
	param($n)
	$s2 = Adb-GetAccessibility
	$s2 += $n
	Adb-SetAccessibility $s2
}

function Adb-SetAccessibility {
	param($s2)
	$v = $s2 -join '/'
	Adb-HandleSettings 'put' 'secure' 'enabled_accessibility_services' $v
}

function Adb-RemoveAccessibility {
	param($n)
	$s2 = (Adb-GetAccessibility | Where-Object { $_ -ne $n })
	Adb-SetAccessibility $s2
} #>


# region Bluetooth

function Blt-Send {
	param($name, $f)

	return Start-Job -Name 'Blt' -ScriptBlock { 
		btobex.exe -n $using:name $using:f
	}
}

# endregion