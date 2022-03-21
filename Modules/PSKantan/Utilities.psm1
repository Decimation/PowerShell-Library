using namespace System.Management.Automation

# region 

$global:UNI_ARROW = $([char]0x2192)
$global:ZERO_WIDTH_SPACE = $([char]"`u{200b}")
$script:SEPARATOR = $([string]::new('-', $Host.UI.RawUI.WindowSize.Width))
$script:UNI_BULLET = '•'
$global:ANSI_START = "$([char]0x001b)"

# endregion



function global:qprint {
	param($rg)
	return [string]($rg -join ',')
}
function Get-SubstringBetween {
	param ([string]$value,
		[string]$a,
		[string]$b)
	
	$posA = $value.IndexOf($a, [System.StringComparison]::Ordinal)
	$posB = $value.LastIndexOf($b, [System.StringComparison]::Ordinal)
	
	$inv = -1
	
	if ($posA -eq $inv -or $posB -eq $inv) {
		return [String]::Empty
	}
	
	$adjustedPosA = $posA + $a.Length
	$pred = $adjustedPosA -ge $posB ? [String]::Empty: $value[$adjustedPosA .. $posB]
	$sz = [string]::new([char[]]$pred)
	
	if ($sz.EndsWith($b)) {
		$sz = $sz.Substring(0, $sz.LastIndexOf($b))
	}
	return $sz
}

function Convert-ObjToHashTable {
	[CmdletBinding()]
	[outputtype([hashtable])]
	param (
		[parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[pscustomobject]$Object
	)
	process {
		$HashTable = @{
		}
		$ObjectMembers = Get-Member -InputObject $Object -MemberType *Property
		foreach ($Member in $ObjectMembers) {
			$HashTable.$($Member.Name) = $Object.$($Member.Name)
		}
		return $HashTable
	}
	
	
}

function Convert-Obj {
	param (
		$a,
		$t
	)
	<# Write-Debug "$( $t)"
	if ($t -is [string]) {
		$t = $t.Substring(1, $t.Length - 2)
		Write-Debug "$( $t)"

		$t2 = [type]::GetType($t)
	}
	else {
		$t2 = $t
	} #>
	return [System.Management.Automation.LanguagePrimitives]::ConvertTo($a, ($t2))
}

Set-Alias cast Convert-Obj
Set-Alias conv Convert-Obj

function Convert-ObjFromHashTable {
	param (
		[parameter(Mandatory = $true)]
		$pred,
		[parameter(Mandatory = $false)]
		$t
	)
	
	$o = New-Object pscustomobject
	$o | Add-Member $pred
	
	if ($t) {
		$o = Convert-Obj $o $t
	}
	
	return $o
}
function Get-PublicIP {
	return (Invoke-WebRequest ifconfig.me/ip).Content.Trim()
	
}


function XRemove {
	param ($x)
	#todo
	
	takeown /F $x /R
	sudo rm -Force $x
}

Set-Alias xrm XRemove


<#
.Description
ffmpeg enhanced passthru
#>
<# function ffmpeg {
	ffmpeg.exe -hide_banner $args
} #>

<#
.Description
ffprobe enhanced passthru
#>
<# function ffprobe {
	ffprobe.exe -hide_banner $args
} #>

<#
.Description
ytmdl enhanced passthru
#>
function ytmdl {
	py.exe (Find-Item ytmdl) $args
}


function typename {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		$x
	)

	process {

		$y = ($x | Get-Member)[0].TypeName
		return $y
	}
	
}

function typeof {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		$x
	)
	process {

		#return [type]::GetType((typename $x))
		return $x.GetType()
	}
}

function typecodeof {
	param ($x)
	$t = $x.GetType()
	$c = [type]::GetTypeCode($t)
	return $c
}

<# function ElevateTerminal {
	Start-Process -Verb RunAs wt.exe
} #>

function OpenLocation {
	param ($p)
	Start-Process $p
}

function OpenHere {
	OpenLocation $(Get-Location)
}

function Get-CommandProcess {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$s
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
function New-QVar {
	param (
		[Parameter(Mandatory = $true)]
		[string]$name,
		[Parameter(Mandatory = $true)]
		$val,
		[Parameter(Mandatory = $false)]
		[string]$scope = 'Global', 
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.ScopedItemOptions]
		$opt = [System.Management.Automation.ScopedItemOptions]::None
	)
	

	$sp = @{
		'Scope'  = $scope
		'Name'   = $name
		'Value'  = $val
		'Option' = $opt
		
	}
	
	Set-Variable @sp -ErrorAction Ignore
}

$STD_IN = 0
$STD_OUT = 1
$STD_ERR = 2


function Invoke-CommandProcess {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		$s,
		[Parameter(Mandatory = $false)]
		[int]$std = $STD_OUT
	)

	$p = Get-CommandProcess $s
	
	$p.Start() | Out-Null
	$p.WaitForExit()
	
	switch ($std) {
		$STD_IN {
			$outStr = $p.StandardInput.ReadToEnd()
		}
		$STD_OUT {
			$outStr = $p.StandardOutput.ReadToEnd()
		}
		$STD_ERR {
			$outStr = $p.StandardError.ReadToEnd()
		}
		Default {}
	}
	
	
	$outStr = $outStr.Trim()
	
	return $outStr
}

function QCommand {
	#todo: use Invoke-Command
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]$s
	)

	return (& cmd.exe /c @s)
}


Set-Alias -Name ic -Value Invoke-Command

function QInvoke($x) {
	# $x = QInvoke("echo hello")
	# $x == "hello"
	$buf2 = (Invoke-Expression -OutVariable $buf ("$x 2>&1"))
	return $buf2
}

function Find-Item {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$s,
		[Parameter(Mandatory = $false)]
		[CommandTypes]$c = [CommandTypes]::All, 
		[switch]$pw = $false
	)
		
	if ((Test-Command 'whereis' Application) -and $pw) {
		return (whereis $s)
	}
		
	return (Get-Command $s -CommandType $c).Path
}
	

Set-Alias whereitem Find-Item

function IsAdmin {
	$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = New-Object Security.Principal.WindowsPrincipal $identity
	return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}


function U {
	#https://mnaoumov.wordpress.com/2014/06/14/unicode-literals-in-powershell/
	
	param ([int]$Code)
	
	if ((0 -le $Code) -and ($Code -le 0xFFFF)) {
		return [char]$Code
	}
	
	if ((0x10000 -le $Code) -and ($Code -le 0x10FFFF)) {
		return [char]::ConvertFromUtf32($Code)
	}
	
	throw "Invalid character code $Code"
}

function Wrap {
	param($i, $n) 
	return (($i % $n) + $n) % $n 
}

function Search-InFiles {
	param (
		[parameter(Mandatory = $true)]
		$filter,
		[parameter(Mandatory = $false)]
		$path,
		[switch]$strict
	)
	
	if (-not $strict) {
		$filter = "*$filter*"
	}
	if (-not ($path)) {
		$path = '.'
	}
	
	return Get-ChildItem -Path $path -Filter "$filter" -Recurse -ErrorAction SilentlyContinue
}

Set-Alias search Search-InFiles

function Flatten($a) {
	, @($a | ForEach-Object { $_ })
}

function Get-Difference {
	param (
		[Parameter(Mandatory = $true)]
		[object[]]$a,
		[Parameter(Mandatory = $true)]
		[object[]]$b
	)
	
	return $b | Where-Object {
		($a -notcontains $_)
	}
}

function Get-Intersection {
	param (
		[Parameter(Mandatory = $true)]
		[object[]]$a,
		[Parameter(Mandatory = $true)]
		[object[]]$b
	)
	return Compare-Object $a $b -PassThru -IncludeEqual -ExcludeDifferent
}

function Get-Union {
	param (
		[Parameter(Mandatory = $true)]
		[object[]]$a,
		[Parameter(Mandatory = $true)]
		[object[]]$b
	)
	return Compare-Object $a $b -PassThru -IncludeEqual
}

function New-List {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		$x
	)
	return New-Object "System.Collections.Generic.List[$x]"
}

function New-RandomArray {
	param (
		[Parameter(Mandatory = $true)]
		[int]$c
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
		[Parameter(Mandatory = $true)]
		[long]$length,
		[Parameter(Mandatory = $false)]
		[string]$file,
		[switch][bool]$nullFile
	)
	
	if (!($file)) {
		$file = $(New-TempFile)
	}
	
	if ((Test-Path $file)) {
		return $false;
	}
	
	$buf = & {
		fsutil file createnew $file $length
	}
	Write-Verbose "$buf"
	
	if (($nullFile)) {
		return;
	}
	
	$fs = [System.IO.File]::OpenWrite($(Resolve-Path $file))
	$rg = [byte[]]$(New-RandomArray $length)
	$fs.Write($rg, 0, $rg.Length)
	$fs.Flush()
	$fs.Close()
	$fs.Dispose()
	
	return $true;
}


function Get-FileBytes {
	param (
		[Parameter(Mandatory = $true)]
		[string]$file
	)
	$b = [System.IO.file]::ReadAllBytes($file)
	return $b
}


function Get-RegistryFileType {
	param (
		[Parameter(Mandatory = $true)]
		[string]$f
	)
	
	$s = ".$($f.Split('.')[-1])"
	$r = Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$s"
	$p = $r | Select-Object -ExpandProperty '(Default)'
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



<#function Get-FileMetadata {
	
	<#
	Adapted from Get-FolderMetadata by Ed Wilson

	https://devblogs.microsoft.com/scripting/list-music-file-metadata-in-a-csv-and-open-in-excel-with-powershell/
	https://web.archive.org/web/20201111223917/https://gallery.technet.microsoft.com/scriptcenter/get-file-meta-data-function-f9e8d804
	>
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$folder,
		[Parameter(Mandatory = $false)]
		[string]$filter
		
	)
	
	$rg = New-List 'psobject'
	$a = 0
	$objShell = New-Object -ComObject Shell.Application
	$objFolder = $objShell.namespace($folder)
	
	$items = $objFolder.items()
	
	if (($filter)) {
		$items = $items | Where-Object {
			$_.Name -contains $filter
		}
	}
	
	foreach ($File in $items) {
		$FileMetaData = New-Object PSOBJECT
		for ($a; $a -le 266; $a++) {
			if ($objFolder.getDetailsOf($File, $a)) {
				$hash += @{
					$($objFolder.getDetailsOf($objFolder.items, $a)) =
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
	
	return $rg
}#>



function Get-SanitizedFilename {
	param (
		$origFileName
	)
	$invalids = [System.IO.Path]::GetInvalidFileNameChars()
	$newName = [String]::Join('_', $origFileName.Split($invalids, 
			[System.StringSplitOptions]::RemoveEmptyEntries)).TrimEnd('.')
	
	return $newName
}


#region [Aliases]

Set-Alias -Name ytdlp -Value yt-dlp.exe
Set-Alias -Name ytdl -Value youtube-dl.exe
Set-Alias -Name gdl -Value gallery-dl.exe
Set-Alias -Name fg -Value ffmpeg
Set-Alias -Name fp -Value ffprobe
Set-Alias -Name mg -Value magick.exe
Set-Alias -Name a2c -Value aria2c

#endregion


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
	} while ($Samples -gt 0)
	
	
	$stats = $timings | Measure-Object -Average -Minimum -Maximum -Property Ticks
	
	# Print the full timespan if the $Long switch was given.
	
	$dict = @{
	}
	
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
		[Parameter(Mandatory, ValueFromPipeline)]
		$x
	)
	process {
		$p = (Get-PSReadLineOption).HistorySavePath
		$c = Get-Content -Path $p
		
		#return $c | Where-Object $x
		return $c | Select-String -Pattern $x
		
		
	}
}

function Get-Bytes {
	[outputtype([byte[]])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline)]
		$x,
		[Parameter(Mandatory = $false)]
		$encoding
	)

	process {

		$isStr = $x -is [string]
		$info1 = @()
		$rg = @()
		
		if ($isStr) {
			if (!($encoding)) {
				$encoding = [System.Text.Encoding]::Default
			}
			
			$info1 += $encoding.EncodingName
			$rg = $encoding.GetBytes($x)
		}
		else {
			$rg = [System.BitConverter]::GetBytes($x)
		}
		
		<# Write-Host "[$($typeX.Name)]" -NoNewline -ForegroundColor Yellow
		
		if ($info1.Length -ne 0) {
			Write-Host ' | ' -NoNewline
			Write-Host "$($info1 -join ' | ')" -NoNewline
		}
		
		Write-Host ' | ' -NoNewline
		Write-Host "$x" -ForegroundColor Cyan #>
		
		return $rg
	}
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
		$a,
		$min,
		$max
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
		[Parameter(ValueFromPipeline, Mandatory)]
		$x
	)
	
	process {
		
		$rg = Get-Bytes $x
		$s = [string]::Join('', [System.Linq.Enumerable]::Select($rg,
				[Func[object, object]] {
					param ($a) [Convert]::ToString($a, 2)
				}))
		
		return $s
	}
}

function Linq-Where {
	
	param (
		[Parameter(ValueFromPipeline)]
		$rg,
		[Parameter()]
		$predicate
	)
	process {
		$predicate = [func[object, bool]]$predicate
		return [System.Linq.Enumerable]::Where($rg, $predicate)
	}	
}
function Linq-First {
	param (
		[Parameter(ValueFromPipeline)]
		$rg,
		[Parameter()]
		$predicate
	)
	process {

		[System.Linq.Enumerable]::First($rg, [System.Func[object, bool]] $predicate)
	}
}

function Linq-Select {
	param (
		[Parameter(ValueFromPipeline)]
		$rg,
		[Parameter()]
		$predicate
	)
	process {
		$predicate = [func[object, object]]$predicate

		return [System.Linq.Enumerable]::Select($rg, $predicate)
	}
}


function Test-Command {
	param (
		[Parameter(Mandatory)]
		$x, 
		[Parameter(Mandatory = $false)]
		[CommandTypes]$c = [CommandTypes]::All
	)
	return ($null -ne (Get-Command -CommandType $c -Name $x -ErrorAction SilentlyContinue))
}


#https://github.com/RamblingCookieMonster/PowerShell/blob/master/Invoke-Parallel.ps1
function Invoke-Parallel {
	<#
    .SYNOPSIS
        Function to control parallel processing using runspaces

    .DESCRIPTION
        Function to control parallel processing using runspaces

            Note that each runspace will not have access to variables and commands loaded in your session or in other runspaces by default.
            This behaviour can be changed with parameters.

    .PARAMETER ScriptFile
        File to run against all input objects.  Must include parameter to take in the input object, or use $args.  Optionally, include parameter to take in parameter.  Example: C:\script.ps1

    .PARAMETER ScriptBlock
        Scriptblock to run against all computers.

        You may use $Using:<Variable> language in PowerShell 3 and later.

            The parameter block is added for you, allowing behaviour similar to foreach-object:
                Refer to the input object as $_.
                Refer to the parameter parameter as $parameter

    .PARAMETER InputObject
        Run script against these specified objects.

    .PARAMETER Parameter
        This object is passed to every script block.  You can use it to pass information to the script block; for example, the path to a logging folder

            Reference this object as $parameter if using the scriptblock parameterset.

    .PARAMETER ImportVariables
        If specified, get user session variables and add them to the initial session state

    .PARAMETER ImportModules
        If specified, get loaded modules and pssnapins, add them to the initial session state

    .PARAMETER Throttle
        Maximum number of threads to run at a single time.

    .PARAMETER SleepTimer
        Milliseconds to sleep after checking for completed runspaces and in a few other spots.  I would not recommend dropping below 200 or increasing above 500

    .PARAMETER RunspaceTimeout
        Maximum time in seconds a single thread can run.  If execution of your code takes longer than this, it is disposed.  Default: 0 (seconds)

        WARNING:  Using this parameter requires that maxQueue be set to throttle (it will be by default) for accurate timing.  Details here:
        http://gallery.technet.microsoft.com/Run-Parallel-Parallel-377fd430

    .PARAMETER NoCloseOnTimeout
        Do not dispose of timed out tasks or attempt to close the runspace if threads have timed out. This will prevent the script from hanging in certain situations where threads become non-responsive, at the expense of leaking memory within the PowerShell host.

    .PARAMETER MaxQueue
        Maximum number of powershell instances to add to runspace pool.  If this is higher than $throttle, $timeout will be inaccurate

        If this is equal or less than throttle, there will be a performance impact

        The default value is $throttle times 3, if $runspaceTimeout is not specified
        The default value is $throttle, if $runspaceTimeout is specified

    .PARAMETER LogFile
        Path to a file where we can log results, including run time for each thread, whether it completes, completes with errors, or times out.

    .PARAMETER AppendLog
        Append to existing log

    .PARAMETER Quiet
        Disable progress bar

    .EXAMPLE
        Each example uses Test-ForPacs.ps1 which includes the following code:
            param($computer)

            if(test-connection $computer -count 1 -quiet -BufferSize 16){
                $object = [pscustomobject] @{
                    Computer=$computer;
                    Available=1;
                    Kodak=$(
                        if((test-path "\\$computer\c$\users\public\desktop\Kodak Direct View Pacs.url") -or (test-path "\\$computer\c$\documents and settings\all users\desktop\Kodak Direct View Pacs.url") ){"1"}else{"0"}
                    )
                }
            }
            else{
                $object = [pscustomobject] @{
                    Computer=$computer;
                    Available=0;
                    Kodak="NA"
                }
            }

            $object

    .EXAMPLE
        Invoke-Parallel -scriptfile C:\public\Test-ForPacs.ps1 -inputobject $(get-content C:\pcs.txt) -runspaceTimeout 10 -throttle 10

            Pulls list of PCs from C:\pcs.txt,
            Runs Test-ForPacs against each
            If any query takes longer than 10 seconds, it is disposed
            Only run 10 threads at a time

    .EXAMPLE
        Invoke-Parallel -scriptfile C:\public\Test-ForPacs.ps1 -inputobject c-is-ts-91, c-is-ts-95

            Runs against c-is-ts-91, c-is-ts-95 (-computername)
            Runs Test-ForPacs against each

    .EXAMPLE
        $stuff = [pscustomobject] @{
            ContentFile = "windows\system32\drivers\etc\hosts"
            Logfile = "C:\temp\log.txt"
        }

        $computers | Invoke-Parallel -parameter $stuff {
            $contentFile = join-path "\\$_\c$" $parameter.contentfile
            Get-Content $contentFile |
                set-content $parameter.logfile
        }

        This example uses the parameter argument.  This parameter is a single object.  To pass multiple items into the script block, we create a custom object (using a PowerShell v3 language) with properties we want to pass in.

        Inside the script block, $parameter is used to reference this parameter object.  This example sets a content file, gets content from that file, and sets it to a predefined log file.

    .EXAMPLE
        $test = 5
        1..2 | Invoke-Parallel -ImportVariables {$_ * $test}

        Add variables from the current session to the session state.  Without -ImportVariables $Test would not be accessible

    .EXAMPLE
        $test = 5
        1..2 | Invoke-Parallel {$_ * $Using:test}

        Reference a variable from the current session with the $Using:<Variable> syntax.  Requires PowerShell 3 or later. Note that -ImportVariables parameter is no longer necessary.

    .FUNCTIONALITY
        PowerShell Language

    .NOTES
        Credit to Boe Prox for the base runspace code and $Using implementation
            http://learn-powershell.net/2012/05/10/speedy-network-information-query-using-powershell/
            http://gallery.technet.microsoft.com/scriptcenter/Speedy-Network-Information-5b1406fb#content
            https://github.com/proxb/PoshRSJob/

        Credit to T Bryce Yehl for the Quiet and NoCloseOnTimeout implementations

        Credit to Sergei Vorobev for the many ideas and contributions that have improved functionality, reliability, and ease of use

    .LINK
        https://github.com/RamblingCookieMonster/Invoke-Parallel
    #>
	[cmdletbinding(DefaultParameterSetName = 'ScriptBlock')]
	Param (
		[Parameter(Mandatory = $false, position = 0, ParameterSetName = 'ScriptBlock')]
		[System.Management.Automation.ScriptBlock]$ScriptBlock,

		[Parameter(Mandatory = $false, ParameterSetName = 'ScriptFile')]
		[ValidateScript({ Test-Path $_ -PathType leaf })]
		$ScriptFile,

		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[Alias('CN', '__Server', 'IPAddress', 'Server', 'ComputerName')]
		[PSObject]$InputObject,

		[PSObject]$Parameter,

		[switch]$ImportVariables,
		[switch]$ImportModules,
		[switch]$ImportFunctions,

		[int]$Throttle = 20,
		[int]$SleepTimer = 200,
		[int]$RunspaceTimeout = 0,
		[switch]$NoCloseOnTimeout = $false,
		[int]$MaxQueue,

		[validatescript({ Test-Path (Split-Path $_ -Parent) })]
		[switch] $AppendLog = $false,
		[string]$LogFile,

		[switch] $Quiet = $false
	)
	begin {
		#No max queue specified?  Estimate one.
		#We use the script scope to resolve an odd PowerShell 2 issue where MaxQueue isn't seen later in the function
		if ( -not $PSBoundParameters.ContainsKey('MaxQueue') ) {
			if ($RunspaceTimeout -ne 0) { $script:MaxQueue = $Throttle }
			else { $script:MaxQueue = $Throttle * 3 }
		}
		else {
			$script:MaxQueue = $MaxQueue
		}
		$ProgressId = Get-Random
		Write-Verbose "Throttle: '$throttle' SleepTimer '$sleepTimer' runSpaceTimeout '$runspaceTimeout' maxQueue '$maxQueue' logFile '$logFile'"

		#If they want to import variables or modules, create a clean runspace, get loaded items, use those to exclude items
		if ($ImportVariables -or $ImportModules -or $ImportFunctions) {
			$StandardUserEnv = [powershell]::Create().addscript({

					#Get modules, snapins, functions in this clean runspace
					$Modules = Get-Module | Select-Object -ExpandProperty Name
					$Snapins = Get-PSSnapin | Select-Object -ExpandProperty Name
					$Functions = Get-ChildItem function:\ | Select-Object -ExpandProperty Name

					#Get variables in this clean runspace
					#Called last to get vars like $? into session
					$Variables = Get-Variable | Select-Object -ExpandProperty Name

					#Return a hashtable where we can access each.
					@{
						Variables = $Variables
						Modules   = $Modules
						Snapins   = $Snapins
						Functions = $Functions
					}
				}).invoke()[0]

			if ($ImportVariables) {
				#Exclude common parameters, bound parameters, and automatic variables
				Function _temp { [cmdletbinding(SupportsShouldProcess = $True)] param() }
				$VariablesToExclude = @( (Get-Command _temp | Select-Object -ExpandProperty parameters).Keys + $PSBoundParameters.Keys + $StandardUserEnv.Variables )
				Write-Verbose "Excluding variables $( ($VariablesToExclude | Sort-Object ) -join ', ')"

				# we don't use 'Get-Variable -Exclude', because it uses regexps.
				# One of the veriables that we pass is '$?'.
				# There could be other variables with such problems.
				# Scope 2 required if we move to a real module
				$UserVariables = @( Get-Variable | Where-Object { -not ($VariablesToExclude -contains $_.Name) } )
				Write-Verbose "Found variables to import: $( ($UserVariables | Select-Object -ExpandProperty Name | Sort-Object ) -join ', ' | Out-String).`n"
			}
			if ($ImportModules) {
				$UserModules = @( Get-Module | Where-Object { $StandardUserEnv.Modules -notcontains $_.Name -and (Test-Path $_.Path -ErrorAction SilentlyContinue) } | Select-Object -ExpandProperty Path )
				$UserSnapins = @( Get-PSSnapin | Select-Object -ExpandProperty Name | Where-Object { $StandardUserEnv.Snapins -notcontains $_ } )
			}
			if ($ImportFunctions) {
				$UserFunctions = @( Get-ChildItem function:\ | Where-Object { $StandardUserEnv.Functions -notcontains $_.Name } )
			}
		}

		#region functions
		Function Get-RunspaceData {
			[cmdletbinding()]
			param( [switch]$Wait )
			#loop through runspaces
			#if $wait is specified, keep looping until all complete
			Do {
				#set more to false for tracking completion
				$more = $false

				#Progress bar if we have inputobject count (bound parameter)
				if (-not $Quiet) {
					Write-Progress -Id $ProgressId -Activity 'Running Query' -Status 'Starting threads'`
						-CurrentOperation "$startedCount threads defined - $totalCount input objects - $script:completedCount input objects processed"`
						-PercentComplete $( Try { $script:completedCount / $totalCount * 100 } Catch { 0 } )
				}

				#run through each runspace.
				Foreach ($runspace in $runspaces) {

					#get the duration - inaccurate
					$currentdate = Get-Date
					$runtime = $currentdate - $runspace.startTime
					$runMin = [math]::Round( $runtime.totalminutes , 2 )

					#set up log object
					$log = '' | Select-Object Date, Action, Runtime, Status, Details
					$log.Action = "Removing:'$($runspace.object)'"
					$log.Date = $currentdate
					$log.Runtime = "$runMin minutes"

					#If runspace completed, end invoke, dispose, recycle, counter++
					If ($runspace.Runspace.isCompleted) {

						$script:completedCount++

						#check if there were errors
						if ($runspace.powershell.Streams.Error.Count -gt 0) {
							#set the logging info and move the file to completed
							$log.status = 'CompletedWithErrors'
							Write-Verbose ($log | ConvertTo-Csv -Delimiter ';' -NoTypeInformation)[1]
							foreach ($ErrorRecord in $runspace.powershell.Streams.Error) {
								Write-Error -ErrorRecord $ErrorRecord
							}
						}
						else {
							#add logging details and cleanup
							$log.status = 'Completed'
							Write-Verbose ($log | ConvertTo-Csv -Delimiter ';' -NoTypeInformation)[1]
						}

						#everything is logged, clean up the runspace
						$runspace.powershell.EndInvoke($runspace.Runspace)
						$runspace.powershell.dispose()
						$runspace.Runspace = $null
						$runspace.powershell = $null
					}
					#If runtime exceeds max, dispose the runspace
					ElseIf ( $runspaceTimeout -ne 0 -and $runtime.totalseconds -gt $runspaceTimeout) {
						$script:completedCount++
						$timedOutTasks = $true
						Write-Verbose "$timedOutTasks"

						#add logging details and cleanup
						$log.status = 'TimedOut'
						Write-Verbose ($log | ConvertTo-Csv -Delimiter ';' -NoTypeInformation)[1]
						Write-Error "Runspace timed out at $($runtime.totalseconds) seconds for the object:`n$($runspace.object | Out-String)"

						#Depending on how it hangs, we could still get stuck here as dispose calls a synchronous method on the powershell instance
						if (!$noCloseOnTimeout) { $runspace.powershell.dispose() }
						$runspace.Runspace = $null
						$runspace.powershell = $null
						$completedCount++
					}

					#If runspace isn't null set more to true
					ElseIf ($runspace.Runspace -ne $null ) {
						$log = $null
						$more = $true
					}

					#log the results if a log file was indicated
					if ($logFile -and $log) {
                            ($log | ConvertTo-Csv -Delimiter ';' -NoTypeInformation)[1] | Out-File $LogFile -Append
					}
				}

				#Clean out unused runspace jobs
				$temphash = $runspaces.clone()
				$temphash | Where-Object { $_.runspace -eq $Null } | ForEach-Object {
					$Runspaces.remove($_)
				}

				#sleep for a bit if we will loop again
				if ($PSBoundParameters['Wait']) { Start-Sleep -Milliseconds $SleepTimer }

				#Loop again only if -wait parameter and there are more runspaces to process
			} while ($more -and $PSBoundParameters['Wait'])

			#End of runspace function
		}
		#endregion functions

		#region Init

		if ($PSCmdlet.ParameterSetName -eq 'ScriptFile') {
			$ScriptBlock = [scriptblock]::Create( $(Get-Content $ScriptFile | Out-String) )
		}
		elseif ($PSCmdlet.ParameterSetName -eq 'ScriptBlock') {
			#Start building parameter names for the param block
			[string[]]$ParamsToAdd = '$_'
			if ( $PSBoundParameters.ContainsKey('Parameter') ) {
				$ParamsToAdd += '$Parameter'
			}

			$UsingVariableData = $Null

			# This code enables $Using support through the AST.
			# This is entirely from  Boe Prox, and his https://github.com/proxb/PoshRSJob module; all credit to Boe!

			if ($PSVersionTable.PSVersion.Major -gt 2) {
				#Extract using references
				$UsingVariables = $ScriptBlock.ast.FindAll({ $args[0] -is [System.Management.Automation.Language.UsingExpressionAst] }, $True)

				If ($UsingVariables) {
					$List = New-Object 'System.Collections.Generic.List`1[System.Management.Automation.Language.VariableExpressionAst]'
					ForEach ($Ast in $UsingVariables) {
						[void]$list.Add($Ast.SubExpression)
					}

					$UsingVar = $UsingVariables | Group-Object -Property SubExpression | ForEach-Object { $_.Group | Select-Object -First 1 }

					#Extract the name, value, and create replacements for each
					$UsingVariableData = ForEach ($Var in $UsingVar) {
						try {
							$Value = Get-Variable -Name $Var.SubExpression.VariablePath.UserPath -ErrorAction Stop
							[pscustomobject]@{
								Name       = $Var.SubExpression.Extent.Text
								Value      = $Value.Value
								NewName    = ('$__using_{0}' -f $Var.SubExpression.VariablePath.UserPath)
								NewVarName = ('__using_{0}' -f $Var.SubExpression.VariablePath.UserPath)
							}
						}
						catch {
							Write-Error "$($Var.SubExpression.Extent.Text) is not a valid Using: variable!"
						}
					}
					$ParamsToAdd += $UsingVariableData | Select-Object -ExpandProperty NewName -Unique

					$NewParams = $UsingVariableData.NewName -join ', '
					$Tuple = [Tuple]::Create($list, $NewParams)
					$bindingFlags = [Reflection.BindingFlags]'Default,NonPublic,Instance'
					$GetWithInputHandlingForInvokeCommandImpl = ($ScriptBlock.ast.gettype().GetMethod('GetWithInputHandlingForInvokeCommandImpl', $bindingFlags))

					$StringScriptBlock = $GetWithInputHandlingForInvokeCommandImpl.Invoke($ScriptBlock.ast, @($Tuple))

					$ScriptBlock = [scriptblock]::Create($StringScriptBlock)

					Write-Verbose $StringScriptBlock
				}
			}

			$ScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock("param($($ParamsToAdd -Join ', '))`r`n" + $Scriptblock.ToString())
		}
		else {
			Throw 'Must provide ScriptBlock or ScriptFile'; Break
		}

		Write-Debug "`$ScriptBlock: $($ScriptBlock | Out-String)"
		Write-Verbose 'Creating runspace pool and session states'

		#If specified, add variables and modules/snapins to session state
		$sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
		if ($ImportVariables -and $UserVariables.count -gt 0) {
			foreach ($Variable in $UserVariables) {
				$sessionstate.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Variable.Name, $Variable.Value, $null) )
			}
		}
		if ($ImportModules) {
			if ($UserModules.count -gt 0) {
				foreach ($ModulePath in $UserModules) {
					$sessionstate.ImportPSModule($ModulePath)
				}
			}
			if ($UserSnapins.count -gt 0) {
				foreach ($PSSnapin in $UserSnapins) {
					[void]$sessionstate.ImportPSSnapIn($PSSnapin, [ref]$null)
				}
			}
		}
		if ($ImportFunctions -and $UserFunctions.count -gt 0) {
			foreach ($FunctionDef in $UserFunctions) {
				$sessionstate.Commands.Add((New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $FunctionDef.Name, $FunctionDef.ScriptBlock))
			}
		}

		#Create runspace pool
		$runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
		$runspacepool.Open()

		Write-Verbose 'Creating empty collection to hold runspace jobs'
		$Script:runspaces = New-Object System.Collections.ArrayList

		#If inputObject is bound get a total count and set bound to true
		$bound = $PSBoundParameters.keys -contains 'InputObject'
		if (-not $bound) {
			[System.Collections.ArrayList]$allObjects = @()
		}

		#Set up log file if specified
		if ( $LogFile -and (-not (Test-Path $LogFile) -or $AppendLog -eq $false)) {
			New-Item -ItemType file -Path $logFile -Force | Out-Null
                ('' | Select-Object -Property Date, Action, Runtime, Status, Details | ConvertTo-Csv -NoTypeInformation -Delimiter ';')[0] | Out-File $LogFile
		}

		#write initial log entry
		$log = '' | Select-Object -Property Date, Action, Runtime, Status, Details
		$log.Date = Get-Date
		$log.Action = 'Batch processing started'
		$log.Runtime = $null
		$log.Status = 'Started'
		$log.Details = $null
		if ($logFile) {
                    ($log | ConvertTo-Csv -Delimiter ';' -NoTypeInformation)[1] | Out-File $LogFile -Append
		}
		$timedOutTasks = $false
		#endregion INIT
	}
	process {
		#add piped objects to all objects or set all objects to bound input object parameter
		if ($bound) {
			$allObjects = $InputObject
		}
		else {
			[void]$allObjects.add( $InputObject )
		}
	}
	end {
		#Use Try/Finally to catch Ctrl+C and clean up.
		try {
			#counts for progress
			$totalCount = $allObjects.count
			$script:completedCount = 0
			$startedCount = 0
			foreach ($object in $allObjects) {
				#region add scripts to runspace pool
				#Create the powershell instance, set verbose if needed, supply the scriptblock and parameters
				$powershell = [powershell]::Create()

				if ($VerbosePreference -eq 'Continue') {
					[void]$PowerShell.AddScript({ $VerbosePreference = 'Continue' })
				}

				[void]$PowerShell.AddScript($ScriptBlock).AddArgument($object)

				if ($parameter) {
					[void]$PowerShell.AddArgument($parameter)
				}

				# $Using support from Boe Prox
				if ($UsingVariableData) {
					Foreach ($UsingVariable in $UsingVariableData) {
						Write-Verbose "Adding $($UsingVariable.Name) with value: $($UsingVariable.Value)"
						[void]$PowerShell.AddArgument($UsingVariable.Value)
					}
				}

				#Add the runspace into the powershell instance
				$powershell.RunspacePool = $runspacepool

				#Create a temporary collection for each runspace
				$temp = '' | Select-Object PowerShell, StartTime, object, Runspace
				$temp.PowerShell = $powershell
				$temp.StartTime = Get-Date
				$temp.object = $object

				#Save the handle output when calling BeginInvoke() that will be used later to end the runspace
				$temp.Runspace = $powershell.BeginInvoke()
				$startedCount++

				#Add the temp tracking info to $runspaces collection
				Write-Verbose ( 'Adding {0} to collection at {1}' -f $temp.object, $temp.starttime.tostring() )
				$runspaces.Add($temp) | Out-Null

				#loop through existing runspaces one time
				Get-RunspaceData

				#If we have more running than max queue (used to control timeout accuracy)
				#Script scope resolves odd PowerShell 2 issue
				$firstRun = $true
				while ($runspaces.count -ge $Script:MaxQueue) {
					#give verbose output
					if ($firstRun) {
						Write-Verbose "$($runspaces.count) items running - exceeded $Script:MaxQueue limit."
					}
					$firstRun = $false

					#run get-runspace data and sleep for a short while
					Get-RunspaceData
					Start-Sleep -Milliseconds $sleepTimer
				}
				#endregion add scripts to runspace pool
			}
			Write-Verbose ( 'Finish processing the remaining runspace jobs: {0}' -f ( @($runspaces | Where-Object { $_.Runspace -ne $Null }).Count) )

			Get-RunspaceData -wait
			if (-not $quiet) {
				Write-Progress -Id $ProgressId -Activity 'Running Query' -Status 'Starting threads' -Completed
			}
		}
		finally {
			#Close the runspace pool, unless we specified no close on timeout and something timed out
			if ( ($timedOutTasks -eq $false) -or ( ($timedOutTasks -eq $true) -and ($noCloseOnTimeout -eq $false) ) ) {
				Write-Verbose 'Closing the runspace pool'
				$runspacepool.close()
			}
			#collect garbage
			[gc]::Collect()
		}
	}
}
function New-PInvoke {
	param (
		$imports,
		$className,
		$dll,
		$returnType,
		$funcName,
		$funcParams
	)
	
	Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;

$imports

public static class $className
{
	[DllImport("$dll", SetLastError = true, CharSet = CharSet.Unicode)]
	public static extern $returnType $funcName($funcParams);
}
"@
}


function New-AdminWT {
	sudo wt -w 0 nt
}


function QGit {
	$f = $args[0]
	
	if ($f) {
		& $f
	}

	git add .
	git commit -m "$(Get-Date -Format 'HH:mm:ss')"
	git push
}