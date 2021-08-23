
[CmdletBinding()]
param (
	[Parameter()][string][ValidateSet("add", "rm")]$opt
)

$script:Key = 'HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\Android\'
$script:KeyCommand = 'HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\Android\command'
$script:AdbPath = (Get-Command adb.exe).Path

function Add-ToContextMenu {
	
	$StudioBin = 'C:\Program Files\Android\Android Studio\bin'
	$StudioIco = "$StudioBin\studio.ico"

	$o1 = (reg.exe add $KeyCommand /ve /d "\`"$AdbPath\`" push \`"%1\`" sdcard/" /f) 2>&1
	
	$o2 = (reg.exe add $Key /v Icon /d "\`"$StudioIco\`"" /f) 2>&1

	Write-Host "Success: $(Check($o1) -and Check($o2))"
}

function Check([string]$x){
	return ([string]$x).Contains("success")
}

function Remove-FromContextMenu {
	
	$o = (reg.exe delete $Key /f) 2>&1

	Write-Host "Success: $(Check($o))"
}


if ($opt -eq 'rm') {
	Remove-FromContextMenu
}
if ($opt -eq 'add') {
	Add-ToContextMenu
}