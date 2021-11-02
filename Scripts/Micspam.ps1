
function __vlc {
	
	&'C:\Program Files\VideoLAN\VLC\vlc.exe' -I dummy --dummy-quiet $args
}

function Find-AudioDevice {
	param (
		[parameter(Mandatory, ValueFromPipeline)]$g
	)
	return Get-AudioDevice -List | Where-Object $g
	
}
function micspam {
	param($f)

	$rec = Find-AudioDevice { $_.Type -match 'Recording' }
	$p = Find-AudioDevice { $_.Type -match 'Playback' }

	$mic1 = $rec | Where-Object { $_.Name -match 'Microphone' }
	$line1rec = $rec | Where-Object { $_.Name -match 'Line 1' }


	#& "audiorepeater.exe /input: `#$($mic1.Index) /output: `#$($line1rec.Index) /autostart /windowname: R1"

	$line1 = $p | Where-Object { $_.Name -match 'Line 1' }

	#Set-AudioDevice -MultimediaDefault -Index $line12.Index

	$id1 = $line1.Id.ToString().Split('}.')[1]

	Write-Host "$($mic1.Index) $($line1rec.Index)"
	Write-Host $id1

	& 'C:\Program Files\VideoLAN\VLC\vlc.exe' -I dummy --dummy-quiet --play-and-exit --aout="directx" --directx-audio-device="$id1" "$f"
	
	#Set-AudioDevice -MultimediaDefault -Index $def1.Index
	#nircmd setdefaultsounddevice 'Line 1 (Rec)'

	#& 'C:\Program Files\VideoLAN\VLC\vlc.exe' -I dummy --dummy-quiet --aout="directx" --directx-audio-device="{cbe17fa5-1e3f-46f0-a75a-79084d265201}" C:\Library\audio\warning.wav
	
	#& 'C:\Program Files\VideoLAN\VLC\vlc.exe' -I dummy --dummy-quiet --aout="waveout" --waveout-audio-device="Headset (2- Logitech G933 Gamin (`$ffff,`$ffff)" C:\Library\audio\warning.wav
	#.\vlc.exe -I dummy --dummy-quiet --aout="waveout" --waveout-audio-device="Headset (2- Logitech G933 Gamin (`$ffff,`$ffff)" C:\Library\audio\warning.wav
}