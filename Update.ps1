$s = "$env:USERPROFILE\Documents\PowerShell"

#$b = Get-ChildItem $s

$cd = Get-Location

#Copy-Item -Path "$s\Modules" -Destination $cd -Recurse -Force

#Copy-Item -Path "$s\Modules\PSKantan\"  -Destination "$cd\Modules\PSKantan\" -Recurse -Force

#Copy-Item -Path "$s\Scripts" -Destination $cd -Recurse -Force
xcopy "$s\*.ps1" "$cd" /y
xcopy "$s\*.psd1" "$cd" /y
xcopy "$s\Scripts" "$cd\Scripts\" /y
xcopy "$s\Scripts\Other" "$cd\Scripts\Other" /y

#Copy-Item -Path "$s\*.ps1" -Destination $cd
#Copy-Item -Path "$s\*.psd1" -Destination $cd

