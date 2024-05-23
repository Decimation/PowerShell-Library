#Requires -Module PSKantan
#Requires -Module Get-MediaInfo

<# function ConvertToTimeSpan([string]$time) {
	$timeParts = $time.Split(':')

	if ($timeParts.Count -lt 1 -or $timeParts.Count -gt 3) {
		Write-Error "Invalid time format. Please use 'hh:mm:ss.fff', 'mm:ss', or 'ss'"
		return $null
	}

	$hours = 0
	$minutes = 0
	$seconds = 0
	$milliseconds = 0

	if ($timeParts.Count -ge 1) {
		$secondsAndMilliseconds = $timeParts[-1].Split('.')
		$seconds = $secondsAndMilliseconds[0]
		if ($secondsAndMilliseconds.Count -eq 2) {
			$milliseconds = $secondsAndMilliseconds[1]
		}
	}

	if ($timeParts.Count -ge 2) {
		$minutes = $timeParts[-2]
	}

	if ($timeParts.Count -eq 3) {
		$hours = $timeParts[0]
	}

	$timeSpan = New-TimeSpan -Hours $hours -Minutes $minutes -Seconds $seconds -Milliseconds $milliseconds

	return $timeSpan
} #>

function ConvertToTimeSpan([string]$time) {
	$timeParts = $time.Split(':')


	$timeSpan = New-TimeSpan
	
	
	switch ($timeParts.Count) {
		1 { 
			$timeSpan = New-TimeSpan -Seconds $timeParts[0] 
		}
		2 { 
			$secondsAndMilliseconds = $timeParts[1].Split('.')
			if ($secondsAndMilliseconds.Count -eq 2) {
				$timeSpan = New-TimeSpan -Minutes $timeParts[0] -Seconds $secondsAndMilliseconds[0] -Milliseconds $secondsAndMilliseconds[1]
			}
			else {
				$timeSpan = New-TimeSpan -Minutes $timeParts[0] -Seconds $timeParts[1]
			}
		}
		3 { 
			$secondsAndMilliseconds = $timeParts[2].Split('.')
			if ($secondsAndMilliseconds.Count -eq 2) {
				$timeSpan = New-TimeSpan -Hours $timeParts[0] -Minutes $timeParts[1] -Seconds $secondsAndMilliseconds[0] -Milliseconds $secondsAndMilliseconds[1]
			}
			else {
				$timeSpan = New-TimeSpan -Hours $timeParts[0] -Minutes $timeParts[1] -Seconds $timeParts[2]
			}
		}
		default { 
			Write-Error "Invalid time format. Please use 'hh:mm:ss.fff', 'mm:ss', or 'ss'"
			return $null
		}
	}

	return $timeSpan
}

function Get-Duration {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Start,

		[Parameter(Mandatory = $true)]
		[string]$End
	)

	
	$startTime = ConvertToTimeSpan $Start
	$endTime = ConvertToTimeSpan $End

	if ($null -eq $startTime -or $null -eq $endTime) {
		return
	}

	$duration = $endTime - $startTime

	return $duration
}

function Get-Clip {
	param (
		[Parameter(Mandatory)]
		$File,

		$Start,
		
		$End,
		
		[Parameter(Mandatory = $false)]
		$Bitrate = '6M',
		
		[Parameter(Mandatory = $false)]
		$cv = 'h264_nvenc',

		[Parameter(Mandatory = $false)]
		$Hwaccel = $null,
		
		[Parameter(Mandatory = $false)]
		$HwaccelOutput = $null,

		$Output,

		[Parameter(Mandatory = $false)]
		$Extra1,

		[Parameter(Mandatory = $false)]
		$Extra2
	)
	
	<# $ffmpegArgs = @()

	if ($Extra1) {
		$ffmpegArgs += $Extra1
	}

	$ffmpegArgs += "-ss $Start"
	$ffmpegArgs += "-i $File"

	if ($dur) {
		$ffmpegArgs += "-t $dur"
	}

	$ffmpegArgs += $cv ? "-c:v $cv" : $null
	$ffmpegArgs += $Bitrate ? "-b:v $Bitrate" : $null

	
	
	if ($Extra2) {
		$ffmpegArgs += $Extra2
	}
	$ffmpegArgs += $Output

	Write-Debug "$ffmpegArgs"
	ffmpeg @ffmpegArgs #>

	$dur = Get-Duration -Start $Start -End $End

	<# if ($Hwaccel) {
		$Extra1 += "-hwaccel $Hwaccel"
	}
	if ($HwaccelOutput) {
		$Extra1 += "-hwaccel_output_format $HwaccelOutput"
	}
	
	$Extra1 = [string]::Join(' ', $Extra1) #>

	<# Write-Debug "$Extra1"
	Write-Debug "$Extra2"
	foreach ($arg in $PSBoundParameters.Keys) {
		Write-Debug "$arg = $($PSBoundParameters[$arg])"
	} #>
	
	ffmpeg -ss $Start -i $File -t $dur -c:v $cv -b:v $Bitrate $Output $Extra2
	
}