
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

<# 
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
} #>

<#
.Description
Deletes file
#>
function Adb-RemoveItem {
	param (
		[Parameter(Mandatory = $true)]
		[string]$src
	)
	$a = @(Remove-Item "$src")
	Invoke-AdbCommand @a
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


function Adb-QPull {
	param(
		$r, 
		[parameter(Mandatory = $false)] 
		$d = $(Get-Location), 
		[switch]$retain
	)
	
	
	if (-not (Test-Path $d)) {
		mkdir $d
	}
	$d = Resolve-Path $d

	Write-Host "$d"
	Read-Host -Prompt "..."
	$r = Adb-GetItems $r -t 'f'


	$st1 = Get-Date

	$r | Invoke-Parallel -Parameter $d -ImportVariables -Quiet -ScriptBlock {
		
		$vx = adb pull $_ "$parameter"
		Write-Verbose "adb >>> $vx"
		

		# $sz = (Get-ChildItem $parameter).count
		$global:SyncState.Counter++
		Write-Host "`r$($global:SyncState.Counter)" -NoNewline

		# $SyncTable.c++
		# Write-Host "`r $($SyncTable.c)/$($SyncTable.l)" -NoNewline

		<# Write-Progress -Activity g -PercentComplete (($i / $l) * 100.0) #>
	}
	
	Write-Host
	$st2 = Get-Date
	$delta = $st2 - $st1
	Write-Host "$($delta.totalseconds)"
	#todo
	
	$global:SyncState = $global:SyncStateEmpty.psobject.copy()
}

$global:SyncStateEmpty = [hashtable]::Synchronized(
	@{
		c       = 0 
		l       = 0
		Counter = 0
	}
)

$global:SyncState = $global:SyncStateEmpty.psobject.copy()

function Adb-GetItems {
	[CmdletBinding()]
	[outputtype([string[]])]
	param (
		[Parameter()]
		$x,
		[Parameter(Mandatory = $false)]
		$t = 'f'
	)
	
	$r = Adb-Find -x $x -type $t
	$r = [string[]] ($r | Sort-Object)

	if ($pattern) {
		$r = $r | Where-Object {
			$_ -match $pattern 
		}
	}
	
	return $r
}


#endregion

Set-Alias Adb-Shell Invoke-AdbCommand
Set-Alias Adb-GetItem Adb-Stat

function Invoke-AdbCommand {
	$rg = @('shell', $args)
	adb @rg
}

function Adb-SendInput {
	param([parameter(ValueFromRemainingArguments)] $a)
	$x = @('input', $a)
	Invoke-AdbCommand @x
}

function Adb-SendFastSwipe {
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
				Adb-SendInput "swipe 500 1000 300 300 $t"
			}
			Up {
				Adb-SendInput "swipe 300 300 500 1000 $t"
			}
		}
		Start-Sleep -Milliseconds $t
	}
}


function Adb-Find {
	[CmdletBinding()]
	[outputtype([string[]])]
	param (
		# [Parameter(Mandatory = $true)]
		$x,
		
		[Parameter(Mandatory = $false)]
		$name,

		[parameter(Mandatory = $false)]
		$type,

		[parameter(Mandatory = $false)]
		$maxdepth = -1
	)
	

	$fa = "%p\\n"
	# $ig = "2>&1 | grep -v `"Permission denied`""
	$a = @("find $x")
	#find 'sdcard/*' -type 'f' -maxdepth 0
	if ($name) {
		$a += '-name', $name
	}
	if ($type) {
		$a += '-type', $type
	}
	if ($maxdepth -ne -1) {
		$a += '-maxdepth', $maxdepth
	}
	$a += '-printf', $fa
	
	$r = Invoke-AdbCommand @a
	
	#TODO

	# $r = $r[1..$r.Length]
	
	return $r
}

function Adb-Stat {
	param (
		$x
	)
	
	$x = Adb-Escape -x $x -e Shell
	
	$d = "   "
	$a = "%n", "%N", "%F", "%w", "%x", "%y", "%z", "%s" -join $d
	$cmd = @("stat -c '$a' $x")
	$out = [string] (Invoke-AdbCommand @cmd)
	$rg = $out -split $d
	$i = 0

	$obj = [PSCustomObject]@{
		Name             = $rg[$i++]
		FullName         = $rg[$i++]
		Type             = $rg[$i++]
		TimeOfBirth      = $rg[$i++]
		LastAccess       = $rg[$i++]
		LastModification = $rg[$i++]
		LastStatusChange = $rg[$i++]
		Size             = $rg[$i++]
		
		IsDirectory      = $null
		IsFile           = $null
		
		Raw              = $out
		Input            = $cmd
	}

	$obj.IsDirectory = $obj.Type -match 'directory'
	$obj.IsFile = $obj.Type -match 'file'
	
	<# $cmd = @('shell', "stat $x")
	$out = [string] (adb @cmd)
	$rg = $out -split "`n" | ForEach-Object { $_.Trim() } #>

	
	return $obj
}

<# 
function Adb-GetItem {
	
	param($x)
	return Adb-Stat $x

	# param (
	# 	$x,
	# 	[Parameter(Mandatory = $false)]
	# 	$x2
	# )
		
	# $a = @('shell', "wc -c $x", '2>&1')
	# $x = adb @a
	# $x = [string]$x
	# Write-Debug "$x| $(typeof $x)"

	# if ($x -match 'Is a directory') {
	# 	$isDir = $true
	# 	$isFile = $false
	# }
	# elseif ($x -match ('No such')) {
	# 	#...
	# 	return
	# }
	# else {
	# 	$isDir = $false
	# 	$isFile = $true
	# 	$size = [int]$x.Split(' ')[0]
	# }
	
	# $buf = @{
	# 	IsFile      = $isFile
	# 	IsDirectory = $isDir
	# 	Size        = $size
	# 	Orig        = $x
	# }
	
	
	# return $buf
} #>

function Adb-GetPackages {
	$aa = @( 'pm list packages -f')
	return (Invoke-AdbCommand @aa)
}


enum EscapeType {
	Shell
	Exchange
}


function Adb-Escape {
	param (
		[Parameter(Mandatory = $true)]
		[string]$x,
		[Parameter(Mandatory = $false)]
		[EscapeType]$e = 'Shell'
	)
	
	switch ($e) {
		Shell {
			# $x = $x.Replace('`', [string]::Empty)
			$x = $x.Replace(' ', '\ ').Replace('(', '\(').Replace(')', '\)')
			
			return $x
		}
		Exchange {
			$s = $x.Split('/')
			$x3 = New-List 'string'
			
			foreach ($b in $s) {
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