#Requires -Module PSKantan
#Requires -Module Get-MediaInfo

function ConvertToTimeSpan([string]$time) {
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
}

<# function ConvertToTimeSpan([string]$time) {
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
 #>
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
		$Hwaccel = 'none',
		
		[Parameter(Mandatory = $false)]
		$HwaccelOutput = 'none',

		$Output
	)
	
	$dur = Get-Duration -Start $Start -End $End

	ffmpeg -hwaccel $Hwaccel -hwaccel_output_format $HwaccelOutput -ss $Start -i $File -t $dur -c:v $cv -b:v $Bitrate $Output
}