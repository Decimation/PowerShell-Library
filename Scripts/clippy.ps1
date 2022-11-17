<#PSScriptInfo

.VERSION 1.5

.GUID dce65b3a-d917-425b-9090-d82b368e12fa

.AUTHOR Read Stanton (Decimation)

.COMPANYNAME

.COPYRIGHT

.TAGS Downloader yt-dlp ffmpeg clip

.LICENSEURI

.PROJECTURI https://github.com/Decimation/PowerShell-Library

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

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
.EXAMPLE
Clip 00:00:13 to the end:
& "clippy.ps1" -Url "https://www.youtube.com/watch?v=IV_H7wsdWFY" -Start 13

#>
param (
	[Parameter(Mandatory)]
	[alias('u')]
	$Url, 
	
	[Parameter(Mandatory)]
	[Alias('s')]
	$Start = '0:0:0', 
	
	[Parameter(Mandatory)]
	[alias('e')]
	$End,

	[Parameter(Mandatory = $false)]
	$Output = $null,

	# yt-dlp args
	[Parameter(Mandatory = $false)]
	$Args1,

	# ffmpeg args
	[Parameter(Mandatory = $false)]
	$Args2 = @('-y', '-preset', 'veryfast'),

	[Alias('cf')]
	[switch]$Confirm
)

#$ErrorActionPreference = 'Abort'
# region Functions

function private:Get-SanitizedFilename {
	param (
		$origFileName, $repl = ''
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

# endregion

$Start = [timespan] (Get-ParsedTime($Start))
$End = [timespan] (Get-ParsedTime($End))

Write-Host "Start: $Start" -ForegroundColor 'Cyan'
Write-Host "End: $End" -ForegroundColor 'Cyan'

$e_ffmpeg = 'ffmpeg'
$e_ytdlp = 'yt-dlp'

$c_ytdlp = (Get-Command $e_ytdlp)
$c_ffmpeg = (Get-Command $e_ffmpeg)

if (-not $c_ytdlp) {
	Write-Error "$e_ytdlp not found"
	return
}

if (-not $c_ffmpeg) {
	Write-Error "$e_ffmpeg not found"
	return
}

Write-Host "$e_ytdlp : $($c_ytdlp.Path)" -ForegroundColor 'DarkGray'
Write-Host "$e_ffmpeg : $($c_ffmpeg.Path)" -ForegroundColor 'DarkGray'

# $tf = "hh\.mm\.ss"
$tf = "hh\hmm\mss\s"

$fs = $Start.ToString($tf)
$fe = $End.ToString($tf)

# $arg2 = @($Url, '--print', 'id')
$arg2 = @($Url, '--print', 'title')

<# $il = [System.IO.Path]::GetInvalidFileNameChars()
$il | ForEach-Object { $s2 = $s -replace ([regex]::Escape($_)), '' } #>

$n1 = "$(yt-dlp @arg2) ($fs - $fe)"

$Output ??= $n1
$Output = Get-SanitizedFilename $Output

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


$duration = $End - $Start
$ts = "*$Start-$End"
$x2Args += $Args1 + @($Url, `
		'--download-sections', $ts, `
		'--postprocessor-args', "ffmpeg:$Args2") `
	 + @('-o', "`"$Output.mp4`"")

Write-Host "Duration: ($duration)" -ForegroundColor 'DarkGray'
Write-Host "final args: $($x2Args -join ' ')" -ForegroundColor 'Cyan'

script:Read-Confirmation

$o_ytdlp = yt-dlp @x2Args

Write-Host "Output: $Output" -ForegroundColor 'Green'

<# $p = Start-Process -FilePath 'ffmpeg.exe' -RedirectStandardOutput:$true `
	-ArgumentList $ffArgs -NoNewWindow -PassThru

return $p #>
