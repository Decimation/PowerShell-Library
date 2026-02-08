param (
	[string]$InputFile,
	[string]$OutputFile = "$(Split-Path $InputFile -Leaf)-shifted.srt",
	[int]$ShiftSeconds
)

function Parse-Time($timeString) {
	if ($timeString -match "(\d{2}):(\d{2}):(\d{2})[.,](\d{3})") {
		$timeString2 = $timeString -replace ',', '.'

		return [TimeSpan]::ParseExact($timeString2, "hh\:mm\:ss\.fff", $null)
	}
 else {
		throw "Invalid time format: $timeString"
	}
}

function Format-Time($timeSpan, $isVtt = $false) {
	$sep = $isVtt ? '.' : ','
	return "{0:00}:{1:00}:{2:00}{3}{4:000}" -f $timeSpan.Hours, $timeSpan.Minutes, $timeSpan.Seconds, $sep, $timeSpan.Milliseconds
}

# Detect format
$isVtt = $InputFile.ToLower().EndsWith(".vtt")

# Read all lines
$lines = Get-Content $InputFile
$adjustedLines = @()

foreach ($line in $lines) {
	if ($line -match "^\s*(\d{2}:\d{2}:\d{2}[.,]\d{3})\s-->\s(\d{2}:\d{2}:\d{2}[.,]\d{3})") {
		$start = Parse-Time $matches[1]
		$end = Parse-Time $matches[2]

		$offset = [TimeSpan]::FromSeconds($ShiftSeconds)
		$newStart = $start + $offset
		$newEnd = $end + $offset

		if ($newStart -lt [TimeSpan]::Zero) {
			$newStart = [TimeSpan]::Zero 
		}
		if ($newEnd -lt [TimeSpan]::Zero) {
			$newEnd = [TimeSpan]::Zero 
		}

		$adjustedLine = "$(Format-Time $newStart $isVtt) --> $(Format-Time $newEnd $isVtt)"
		$adjustedLines += $adjustedLine
	}
 else {
		$adjustedLines += $line
	}
}

# Save result
$adjustedLines | Set-Content -Encoding UTF8 $OutputFile
Write-Host "Subtitle timing adjusted by $ShiftSeconds seconds and saved to '$OutputFile'"
