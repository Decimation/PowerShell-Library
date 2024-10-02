$host.UI.RawUI.WindowTitle = "Auto"

Write-Host "Running"

xcopy "$env:APPDATA\..\LocalLow\MCC\Temporary\UserContent\*.*" "E:\Recording\Halo\" /S /Y /D

Write-Host "Done"

Start-Sleep -Seconds 3