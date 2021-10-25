<#
# General utilities
#>

function typename {
	param ($x)

	$y = ($x | Get-Member)[0].TypeName

	return $y
}

function typeof {
	param ($x)

	#return [type]::GetType((typename $x))
	return $x.GetType()
}

function ElevateTerminal { Start-Process -Verb RunAs wt.exe }

function OpenLocation { param($p) Start-Process $p }

function OpenHere { OpenLocation $(Get-Location) }

function Get-CommandProcess {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)][string]$s
	)

	$pinfo = New-Object System.Diagnostics.ProcessStartInfo
	$pinfo.FileName = 'cmd.exe'

	$pinfo.RedirectStandardError = $true
	$pinfo.RedirectStandardOutput = $true
	$pinfo.UseShellExecute = $false

	$pinfo.Arguments = "/c $s"

	$p = New-Object System.Diagnostics.Process
	$p.StartInfo = $pinfo

	return $p
}

function QCommand {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)][string]$s,
		[switch]$d
	)

	if ($d) {
		return (cmd.exe /c $s)
	}

	$p = Get-CommandProcess $s

	$p.Start() | Out-Null
	$p.WaitForExit()

	$stdout = $p.StandardOutput.ReadToEnd()
	#$stderr = $p.StandardError.ReadToEnd()

	$stdout = $stdout.Trim()
	return $stdout
}


function QInvoke($x) {
	# $x = QInvoke("echo hello")
	# $x == "hello"
	$buf2 = (Invoke-Expression -OutVariable $buf ("$x 2>&1"))
	return $buf2
}

function WhereItem {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)][string]$s,
		[Parameter(Mandatory = $false)][System.Management.Automation.CommandTypes]$c
	)

	if (!($c)) {
		$c = [System.Management.Automation.CommandTypes]::Application
	}
	return (Get-Command $s -CommandType $c).Path
}


function IsAdmin {
	$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = New-Object Security.Principal.WindowsPrincipal $identity
	return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Get-IP {

	$wc = [System.Net.WebClient]::new()

	$ip = $wc.DownloadString('https://icanhazip.com/').Trim()

	#$ipstr = $wc.DownloadString('https://icanhazip.com/').Trim()
	#$ip = [ipaddress]::Parse($ipstr)

	$wc.Dispose()

	return $ip
}

function DumpBytes {
	param (
		[Parameter(Mandatory = $true)]$x
	)

	Write-Host "[$($x.GetType())] : $x"

	([System.BitConverter]::GetBytes($x)) | ForEach-Object {
		Write-Host "$($_.ToString('X')) " -NoNewline
	}
}


function ForceKill {
	param (
		[Parameter(Mandatory = $true)][string]$name
	)

	# Stop-Process (Get-Process $name).Id
	return (taskkill.exe /f /im $name)
}


function ffprobeq { ffprobe.exe -hide_banner $args }

function ffmpegq { ffmpeg.exe -hide_banner $args }

function ytmdl { py (WhereItem ytmdl) $args }


function U {
	#https://mnaoumov.wordpress.com/2014/06/14/unicode-literals-in-powershell/

	param(
		[int] $Code
	)

	if ((0 -le $Code) -and ($Code -le 0xFFFF)) {
		return [char] $Code
	}

	if ((0x10000 -le $Code) -and ($Code -le 0x10FFFF)) {
		return [char]::ConvertFromUtf32($Code)
	}

	throw "Invalid character code $Code"
}


function PathJoin($x, $d) {
	return [string]::Join($d, $x).TrimEnd($d)
}

function Flatten($a) {
	, @($a | ForEach-Object { $_ })
}

function Get-Difference {
	param (
		[Parameter(Mandatory = $true)][object[]]$a,
		[Parameter(Mandatory = $true)][object[]]$b
	)

	return $b | Where-Object { ($a -notcontains $_) }
}

function Get-Intersection {
	param (
		[Parameter(Mandatory = $true)][object[]]$a,
		[Parameter(Mandatory = $true)][object[]]$b
	)
	return Compare-Object $a $b -PassThru -IncludeEqual -ExcludeDifferent
}

function Get-Union {
	param (
		[Parameter(Mandatory = $true)][object[]]$a,
		[Parameter(Mandatory = $true)][object[]]$b
	)
	return Compare-Object $a $b -PassThru -IncludeEqual
}

function New-List {
	param (
		[Parameter(Mandatory = $true)][string]$x
	)
	#return New-Object -TypeName System.Collections.Generic.List[string]
	return New-Object "System.Collections.Generic.List[$x]"
}

function New-RandomArray {
	param (
		[Parameter(Mandatory = $true)][int]$c
	)
	$rg = [byte[]]::new($c)
	$rand = [System.Random]::new()
	<# for ($i = 0; $i -lt $rg.Count; $i++) {
		$rg[$i] = [byte] $rand.Next()
	} #>
	$rand.NextBytes($rg)
	return $rg
}

function DateAdd {
	param (
		[Parameter(Mandatory = $true)][datetime]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)
	return $a + $b
}
function DateSub {
	param (
		[Parameter(Mandatory = $true)][datetime]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)
	return $a - $b
}

function TimeAdd {
	param (
		[Parameter(Mandatory = $true)][timespan]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)

	return $a + $b
}

function TimeSub {
	param (
		[Parameter(Mandatory = $true)][timespan]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)

	return $a - $b
}

function TimeAbs {
	param (
		[Parameter(Mandatory = $true)][timespan]$c
	)
	return [timespan]::FromTicks([System.Math]::Abs($c.Ticks))
}



function Get-TimeDuration {
	param (
		[Parameter(Mandatory = $true)][timespan]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)

	$a = [timespan]::Parse($a)
	$b = [timespan]::Parse($b)

	$c = (TimeSub $a $b)

	<#if ([timespan]::op_LessThan($c, [timespan]::Zero)) {

	}#>

	$c = [timespan]::FromTicks([System.Math]::Abs($c.Ticks))

	return $c;
}

function Get-TimeDurationString {
	param(
		[Parameter(Mandatory = $true)][timespan]$a,
		[Parameter(Mandatory = $true)][timespan]$b
	)

	return (Get-TimeDuration $a $b).ToString('hh\:mm\:ss')
}


function New-TempFile {
	return [System.IO.Path]::GetTempFileName()
}

function New-RandomFile {
	param (
		[Parameter(Mandatory = $true)][int]$x,
		[Parameter(Mandatory = $false)][string]$f
	)

	if (!($f)) {
		$f = $(New-TempFile)
	}

	[System.IO.file]::WriteAllBytes($f, $(New-RandomArray $x))

	return $f
}

function Get-FileBytes {
	param (
		[Parameter(Mandatory = $true)][string]$s
	)
	#Add-Type -MemberDefinition $sig -Name Win32 -Namespace PInvoke -Using PInvoke,System.Text;
	$b = [System.IO.file]::ReadAllBytes($s)
	return $b
}


function Get-FileType {
	param (
		[Parameter(Mandatory = $true)][string]$f
	)

	$s = ".$($f.Split('.')[-1])"

	$r = Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$s"

	$p = $r | so -ExpandProperty '(Default)'

	$r2 = Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$p"

	Write-Host $r.'(default)'
	Write-Host $r.'Content Type'
	Write-Host $r.'PerceivedType'
	Write-Host $r2.'(default)'

	return $r
}

function ConvertFrom-Base64 {
	param (
		$s
	)
	$g = [System.Convert]::FromBase64String($s)
	$s2 = [System.Text.Encoding]::UTF8.GetString($g)
	return $s2
}

# region [Aliases]

Set-Alias -Name ytdlp -Value yt-dlp.exe
Set-Alias -Name ytdl -Value youtube-dl.exe
Set-Alias -Name gdl -Value gallery-dl.exe
Set-Alias -Name yg -Value you-get.exe
Set-Alias -Name fg -Value ffmpeg.exe
Set-Alias -Name fp -Value ffprobe.exe
Set-Alias -Name mg -Value magick.exe

Set-Alias -Name ffp -Value ffprobeq
Set-Alias -Name ffm -Value ffmpegq
Set-Alias -Name a2c -Value aria2c

# endregion

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
	param($commandName, $wordToComplete, $cursorPosition)
	dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}

function Get-FileMetadata {

	<#
	Adapted from Get-FolderMetadata by Ed Wilson

	https://devblogs.microsoft.com/scripting/list-music-file-metadata-in-a-csv-and-open-in-excel-with-powershell/
	https://web.archive.org/web/20201111223917/https://gallery.technet.microsoft.com/scriptcenter/get-file-meta-data-function-f9e8d804
	#>

	param (
		[Parameter(Mandatory = $true)][string]$folder,
		[Parameter(Mandatory = $false)][string]$filter

	)

	$rg = New-List 'psobject'
	$a = 0
	$objShell = New-Object -ComObject Shell.Application
	$objFolder = $objShell.namespace($folder)

	$items = $objFolder.items()

	if (($filter)) {
		$items = $items | Where-Object { $_.Name -contains $filter }
	}

	foreach ($File in $items) {
		$FileMetaData = New-Object PSOBJECT
		for ($a ; $a -le 266; $a++) {
			if ($objFolder.getDetailsOf($File, $a)) {
				$hash += @{$($objFolder.getDetailsOf($objFolder.items, $a)) =
					$($objFolder.getDetailsOf($File, $a))
				}
				$FileMetaData | Add-Member $hash
				$hash.clear()
			}
		}
		$a = 0
		#$FileMetaData

		$rg.Add($FileMetaData)

	}
	Return $rg
}


function Add-ExifTag {
	param (
		$file, $tag, $id
	)

	$buf = (exiftool -overwrite_original -$id="$tag" $file)

	return $buf
}