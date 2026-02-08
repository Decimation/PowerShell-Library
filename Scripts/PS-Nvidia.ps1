function Get-NvApps {
	param (
	)
	
	$apps = Get-Content "$env:LOCALAPPDATA\NVIDIA Corporation\NVIDIA app\NvBackend\ApplicationStorage.json" | ConvertFrom-Json
	return $apps.Applications
}