
param (
	[string] $mpvPath,
	[string] $iconPath
)

# Ensure the script is running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Write-Warning "You need to run this script as an Administrator."
	exit
}


# Check if mpv.exe exists
if (-not (Test-Path $mpvPath)) {
	Write-Error "mpv.exe not found at $mpvPath"
	exit
}

# Check if mpv-icon.ico exists
if (-not (Test-Path $iconPath)) {
	Write-Error "mpv-icon.ico not found at $iconPath"
	exit
}

# Register mpv.exe under the "App Paths" key
$appPathsKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\mpv.exe"
Set-ItemProperty -Path $appPathsKey -Name "(Default)" -Value $mpvPath -Force
Set-ItemProperty -Path $appPathsKey -Name "UseUrl" -Type DWord -Value 1 -Force

# Register mpv.exe under the "Applications" key
$classesRootKey = "HKLM:\SOFTWARE\Classes"
$appKey = "$classesRootKey\Applications\mpv.exe"
Set-ItemProperty -Path $appKey -Name "FriendlyAppName" -Value "mpv" -Force

# Add mpv to the "Open with" list for all video and audio file types
$videoKey = "$classesRootKey\SystemFileAssociations\video\OpenWithList\mpv.exe"
New-Item -Path $videoKey -Force

Write-Output "mpv.exe has been registered as a media player."