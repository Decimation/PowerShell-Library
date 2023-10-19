$i = 0
while ($true) {
	adb shell input keyevent 66
	adb shell input keyevent 279
	Start-Sleep -Milliseconds 100
	Write-Host "`r$i" -NoNewline
	$i++
}
