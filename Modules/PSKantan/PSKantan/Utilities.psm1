
$global:UNI_ARROW = $([char]0x2192)
$global:ZERO_WIDTH_SPACE = $([char]"`u{200b}")

$script:SEPARATOR = $([string]::new('-', $Host.UI.RawUI.WindowSize.Width))
$global:ANSI_UNDERLINE = "$([char]0x1b)[4m"
$global:ANSI_END = "$([char]0x001b)[0m"


<#
.Description
ffmpeg enhanced passthru
#>
function ffmpeg {
	ffmpeg.exe -hide_banner $args
}

<#
.Description
ffprobe enhanced passthru
#>
function ffprobe {
	ffprobe.exe -hide_banner $args
}

<#
.Description
ytmdl enhanced passthru
#>
function ytmdl {
	py.exe (WhereItem ytmdl) $args
}


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

function typecodeof {
	param ($x)
	$t = $x.GetType()
	$c = [type]::GetTypeCode($t)
	return $c
}

function ElevateTerminal {
	Start-Process -Verb RunAs wt.exe
}

function OpenLocation {
	param($p)
	Start-Process $p
}

function OpenHere {
	OpenLocation $(Get-Location)
}

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

	$wc.Dispose()

	return $ip
}




function ForceKill {
	param (
		[Parameter(Mandatory = $true)][string]$name
	)

	# Stop-Process (Get-Process $name).Id
	return (taskkill.exe /f /im $name)
}

Set-Alias -Name fk -Value ForceKill


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
		[Parameter(ParameterSetName = 'name', Position = 0)][string]$x,
		[Parameter(ParameterSetName = 'type', Position = 0)][type]$typeX
	)

	return New-Object "System.Collections.Generic.List[$x]"
}

function New-RandomArray {
	param (
		[Parameter(Mandatory = $true)][int]$c
	)
	$rg = [byte[]]::new($c)
	$rand = [System.Random]::new()
	$rand.NextBytes($rg)
	return $rg
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

	[System.IO.File]::WriteAllBytes($f, $(New-RandomArray $x))

	return $f
}

function Get-FileBytes {
	param (
		[Parameter(Mandatory = $true)][string]$s
	)
	$b = [System.IO.file]::ReadAllBytes($s)
	return $b
}


function Get-RegistryFileType {
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
function ConvertTo-Extension {
	param($items, $ext)

	$items | ForEach-Object {
		$x = [System.IO.Path]::GetFileNameWithoutExtension($_) + $ext
		$y = [System.IO.Path]::GetDirectoryName($_)

		ffmpeg.exe -i $_ ($y + '\' + $x)
	}
}
function Get-SanitizedFilename {
	param (
		$origFileName
	)
	$invalids = [System.IO.Path]::GetInvalidFileNameChars()
	$newName = [String]::Join('_', $origFileName.Split($invalids, [System.StringSplitOptions]::RemoveEmptyEntries)).TrimEnd('.')

	return $newName
}
# region [Aliases]

Set-Alias -Name ytdlp -Value yt-dlp.exe
Set-Alias -Name ytdl -Value youtube-dl.exe
Set-Alias -Name gdl -Value gallery-dl.exe
Set-Alias -Name yg -Value you-get.exe
Set-Alias -Name fg -Value ffmpeg
Set-Alias -Name fp -Value ffprobe
Set-Alias -Name mg -Value magick.exe

Set-Alias -Name a2c -Value aria2c

# endregion


<#
.SYNOPSIS
  Runs the given script block and returns the execution duration.
  Discovered on StackOverflow. http://stackoverflow.com/questions/3513650/timing-a-commands-execution-in-powershell
  Adapted by Read Stanton

.EXAMPLE
  Measure-CommandEx { ping -n 1 google.com }
#>
function Measure-CommandEx ([ScriptBlock]$Expression, [int]$Samples = 1, [Switch]$Silent, [Switch]$Long) {

	$timings = @()
	do {
		$sw = New-Object Diagnostics.Stopwatch
		if ($Silent) {
			$sw.Start()
			$null = & $Expression
			$sw.Stop()
			Write-Host '.' -NoNewline
		}
		else {
			$sw.Start()
			& $Expression
			$sw.Stop()
		}
		$timings += $sw.Elapsed

		$Samples--
	}
	while ($Samples -gt 0)


	$stats = $timings | Measure-Object -Average -Minimum -Maximum -Property Ticks

	# Print the full timespan if the $Long switch was given.

	$dict = @{}

	if ($Long) {
		$dict = @{
			'Avg' = $((New-Object System.TimeSpan $stats.Average).ToString());
			'Min' = $((New-Object System.TimeSpan $stats.Minimum).ToString());
			'Max' = $((New-Object System.TimeSpan $stats.Maximum).ToString());
		}
	}
	else {
		$dict = @{
			'Avg' = "$((New-Object System.TimeSpan $stats.Average).TotalMilliseconds.ToString()) ms";
			'Min' = "$((New-Object System.TimeSpan $stats.Minimum).TotalMilliseconds.ToString()) ms";
			'Max' = "$((New-Object System.TimeSpan $stats.Maximum).TotalMilliseconds.ToString()) ms";
		}
	}

	return $dict

}

Set-Alias time Measure-CommandEx



function Search-History {
	param (
		[Parameter(Mandatory, ValueFromPipeline)]$x
	)
	process {
		$p = (Get-PSReadLineOption).HistorySavePath
		$c = Get-Content -Path $p


		return $c | Where-Object $x
	}
}

function Get-Bytes {
	param (
		[Parameter(Mandatory = $true)]$x,
		[Parameter(Mandatory = $false)][System.Text.Encoding]$encoding
	)

	$isStr = $x -is [string]
	$typeX = $x.GetType()
	$info1 = @()
	$rg = @()

	if ($isStr) {
		$typeX = [string]

		if (!($encoding)) {
			$encoding = [System.Text.Encoding]::Default
		}

		$info1 += $encoding.EncodingName
		$rg = $encoding.GetBytes($x)
	}
	else {
		$rg = [System.BitConverter]::GetBytes($x)
	}

	Write-Host "[$($typeX.Name)]" -NoNewline -ForegroundColor Yellow

	if ($info1.Length -ne 0) {
		Write-Host ' | ' -NoNewline
		Write-Host "$($info1 -join ' | ')" -NoNewline
	}

	Write-Host ' | ' -NoNewline
	Write-Host "$x" -ForegroundColor Cyan

	return $rg
}

function ConvertTo-String {
	param (
		[Parameter(Mandatory = $true)][byte[]]$x,
		[Parameter(Mandatory = $false)][System.Text.Encoding]$encoding

	)

	if (!($encoding)) {
		$encoding = [System.Text.Encoding]::Default
	}

	return $encoding.GetString($x)
}


function IsReal {
	param (
		$x
	)
	$c = typecodeof $x

	return IsInRange $c ([System.TypeCode]::Decimal) ([System.TypeCode]::Single)
}

function IsInteger {
	param (
		$x
	)
	$c = typecodeof $x

	return IsInRange $c ([System.TypeCode]::UInt64) ([System.TypeCode]::SByte)
}

function IsInRange {
	param (
		$a, $min, $max
	)

	return $a -le $min -and $c -ge $max
}

function IsNumeric {
	param (
		$x
	)
	return (IsInteger $x) -or (IsReal $x)
}


function Format-Binary {
	param (
		[Parameter(ValueFromPipeline, Mandatory)]$x
	)

	process {

		$rg = Get-Bytes $x
		$s = [string]::Join('', [System.Linq.Enumerable]::Select($rg,
				[Func[object, object]] { param($a) [Convert]::ToString($a, 2) }))

		return $s
	}
}

Set-Alias -Name cts -Value ConvertTo-String

Set-Alias -Name gb -Value Get-Bytes

Set-Alias -Name fhx -Value Format-Hex