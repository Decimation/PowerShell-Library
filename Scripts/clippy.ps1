<#PSScriptInfo

.VERSION 1.9

.GUID dce65b3a-d917-425b-9090-d82b368e12fa

.AUTHOR Read Stanton (Decimation)

.COMPANYNAME

.COPYRIGHT

.TAGS Downloader yt-dlp ffmpeg clip youtube media

.LICENSEURI

.PROJECTURI https://github.com/Decimation/PowerShell-Library

.ICONURI

.EXTERNALMODULEDEPENDENCIES PSKantan,RoughDraft

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

.PRIVATEDATA

#>

<#
.DESCRIPTION
Downloads clips from sites supported by yt-dlp
.PARAMETER Url
Url
.PARAMETER Start
Start time
.PARAMETER End
End time
.PARAMETER Args1
Extra yt-dlp args
.PARAMETER Args2
Extra ffmpeg args
.LINK
https://github.com/Decimation/PowerShell-Library
.EXAMPLE
& "clippy.ps1" -Url "https://www.youtube.com/watch?v=SNgNBsCI4EA" -Start '1:10' -End "1:26"
.EXAMPLE
& "clippy.ps1" -Url "https://youtu.be/YPqYvll6XD0" -Start '10:52' -End "11:38" -Args2 @('-preset','veryfast')
.EXAMPLE
& "clippy.ps1" -u "https://youtu.be/YPqYvll6XD0" -s '1:00' -e "2:00" -Args2 @('-preset','ultrafast')
.EXAMPLE
& "clippy.ps1" -Url "https://www.youtube.com/watch?v=lGJBUauU-CE" -Start 1:00 -End 3:00 -Args2 @('-c','copy')

#>
param (
	[Parameter(Mandatory)]
	[alias('u')]
	$Url, 
	
	[Parameter(Mandatory)]
	[Alias('s')]
	$Start = '0:0:0', 
	
	[Parameter(Mandatory = $false, ParameterSetName = 'TimeAbsolute')]
	[alias('e')]
	$End,

	[Parameter(Mandatory = $false, ParameterSetName = 'TimeDuration')]
	[alias('d')]
	$Duration,

	[Parameter(Mandatory = $false)]
	$Output,

	# yt-dlp args
	[Parameter(Mandatory = $false)]
	$Args1,

	# ffmpeg args
	[Parameter(Mandatory = $false)]
	$Args2 = @('-y', '-preset', 'veryfast'),

	[Alias('cf')]
	[switch]
	$Confirm,

	[switch]
	$IgnoreConfig
)

#$ErrorActionPreference = 'Abort'
# region Functions

function private:Get-SanitizedFilename {
	param (
		$origFileName,
		$repl = ''
	)

	$invalids = [System.IO.Path]::GetInvalidFileNameChars()
	$newName = [String]::Join($repl, $origFileName.Split($invalids, 
			[System.StringSplitOptions]::RemoveEmptyEntries)).TrimEnd('.')
	
	return $newName
}

function script:Get-ParsedTime {
	[Outputtype([timespan])]
	param ([string]$t)

	$st = $t.Split(':')

	switch ($st.Length) {
		1 {
			$t = [TimeSpan]::FromSeconds($t)
			return $t;
		}
		2 {
			$t = "0:" + $t
		}
		
	}
	
	try {
		$t = [timespan]::ParseExact($t, "g", [cultureinfo]::CurrentCulture)	
	}
	catch {
		$t = ([timespan]::Parse($t))
	}

	return [timespan] $t
}


function script:Read-Confirmation {
	
	if ($Confirm) {
		switch (Read-Host "Continue? [y/n] (or press enter)") {
			default {
				
			}
			'y' {
				
			}
			'n' {
				exit
			}
		}
	}

}
function script:Find-MediaCommand {
	
	param($c)
	$c2 = (Get-Command $c -ErrorAction SilentlyContinue -CommandType All)
	if (-not $c2) {
		throw "$c not found"
		return
	}
	Write-Host "$c : $($c2.Path)" -ForegroundColor 'DarkGray'
	return $c2
}

# endregion

Write-Debug "$Url $Start $End $Duration"

$e_ffmpeg = 'ffmpeg'
$e_ytdlp = 'yt-dlp'

$c_ytdlp = script:Find-MediaCommand $e_ytdlp
$c_ffmpeg = script:Find-MediaCommand $e_ffmpeg

if (-not $End -and -not $Duration) {
	$targs = @('--print', 'duration_string', $Url)
	$End = & $c_ytdlp @targs
	Write-Host "Automatically retrieved end time: $End"
}

$Start = [timespan] (Get-ParsedTime($Start))
if ($End) {
	$End = [timespan] (Get-ParsedTime($End))
}
elseif ($Duration -and -not $End) {
	$End = $Start + ([timespan] (Get-ParsedTime($Duration)))
	
}
Write-Host "Start: $Start" -ForegroundColor 'Cyan'
Write-Host "End: $End" -ForegroundColor 'Cyan'


# $tf = "hh\.mm\.ss"
$tf = "hh\hmm\mss\s"

$fs = $Start.ToString($tf)
$fe = $End.ToString($tf)

# $arg2 = @($Url, '--print', 'id')
# $arg2 = @($Url, '--print', "%(title)s.%(ext)s") + $Args1

<# $il = [System.IO.Path]::GetInvalidFileNameChars()
$il | ForEach-Object { $s2 = $s -replace ([regex]::Escape($_)), '' } #>

# $n1 = "$(& $c_ytdlp @arg2) ($fs - $fe)"
# $n1 = "$(& $c_ytdlp @arg2)"

$title = &$c_ytdlp $(@($Url, '--print', '%(title)s') + $Args1)
$ext = &$c_ytdlp $(@($Url, '--print', '%(ext)s') + $Args1)

if ($Output) {
	if ([System.IO.Path]::HasExtension($Output)) {
		# $Output = [System.IO.Path]::GetFileNameWithoutExtension($Output)
		$ext=[System.IO.Path]::GetExtension($Output)
	}else{
		$Output="$Output.$ext"
	}
}
else{
	$Output="$title ($fs - $fe).$ext"
}

Write-Debug "$title $ext $Output"

# $Output ??= $n1
#$Output = Get-SanitizedFilename $Output

Write-Host "Output filename: $Output" -ForegroundColor 'Green'

if (Test-Path $Output) {
	$yn = Read-Host -Prompt "$Output already exists. Remove? [y/n/a]"
	switch ($yn) {
		'y' {
			Remove-Item $Output
		}
		'n' {
			
		}
		'a' {
			return
		}
	}
}


script:Read-Confirmation

# yt-dlp args

if ($End) {
	$duration1 = $End - $Start
}
elseif ($Duration) {
	$duration1 = $Start + $Duration
}

Write-Host "Duration: ($duration1)" -ForegroundColor 'DarkGray'

$ts = "*$Start-$End"
$x2Args += $Args1 + @($Url, `
		'--force-keyframes-at-cuts', `
		'--download-sections', $ts, `
		'--postprocessor-args', "ffmpeg:$Args2") `
	+ @('-o', "$Output")

if ($IgnoreConfig) {
	$x2Args += @('--ignore-config')
}

Write-Host "final args: $($x2Args -join ' ')" -ForegroundColor 'Cyan'

script:Read-Confirmation

$o_ytdlp = & $c_ytdlp @x2Args

Write-Host "$o_ytdlp"
Write-Host "Output: $Output" -ForegroundColor 'Green'

<# $p = Start-Process -FilePath 'ffmpeg.exe' -RedirectStandardOutput:$true `
	-ArgumentList $ffArgs -NoNewWindow -PassThru

return $p #>
