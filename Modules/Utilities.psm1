<#
# General utilities
#>

function ElevateTerminal { Start-Process -Verb RunAs wt.exe }

function OpenHere { Start-Process $(Get-Location) }

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
		return (cmd /c $s)
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
	return (taskkill /f /im $name)
}


function ffprobeq { ffprobe.exe -hide_banner $args }

function ffmpegq { ffmpeg.exe -hide_banner $args }

function ytmdl { py (WhereItem ytmdl) $args }

function Get-Translation {
	param (
		[Parameter(Mandatory = $true)][string]$x,
		[Parameter(Mandatory = $true)][string]$y
	)

	$cmd = @(
		'from googletrans import *',
		"tmp = Translator().translate('$x', dest='$y')",
		"print('{0} ({1})'.format(tmp.text, tmp.pronunciation))"
		<# "ed = tmp.extra_data['all-translations']"
		"for i in range(len(ed)):"
		"	for j in range(len(ed[i])):"
		"		print(','.join(ed[i][j]))" #>
	)

	#Translator().translate('energy', dest='ja').extra_data['all-translations']

	$f1 = $(Get-TempFile)
	$cmd | Out-File $f1
	python $f1

	$cmd2 = @(
		'from translatepy import *',
		"tmp2 = Translator().translate('$x', '$y')",
		'print(tmp2)'
	)

	$f2 = $(Get-TempFile)
	$cmd2 | Out-File $f2
	python $f2
}


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


function Get-TempFile {
	return [System.IO.Path]::GetTempFileName()
}

function Get-RandFile {
	param (
		[Parameter(Mandatory = $true)][int]$x,
		[Parameter(Mandatory = $false)][string]$f
	)

	if (!($f)) {
		$f = $(Get-TempFile)
	}

	[System.IO.File]::WriteAllBytes($f, $(New-RandomArray $x))

	return $f
}

function Get-FileBytes {
	param (
		[Parameter(Mandatory = $true)][string]$s
	)
	#Add-Type -MemberDefinition $sig -Name Win32 -Namespace PInvoke -Using PInvoke,System.Text;
	$b = [System.IO.File]::ReadAllBytes($s)
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


