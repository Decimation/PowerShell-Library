$script:CONFIG_MMF_NAME = "{8BA1E16C-FC54-4595-9782-E370A5FBE8DA}"

function Get-NvConfig {
		
	$content = $null

	try {
		$mmf = [System.IO.MemoryMappedFiles.MemoryMappedFile]::OpenExisting($CONFIG_MMF_NAME)
		$cs = $mmf.CreateViewStream()
		$sr = New-Object System.IO.StreamReader($cs)
		
		$content = $sr.ReadToEnd() | ConvertFrom-Json
	}
	catch {
		throw
	}
	finally {
		$mmf.Dispose()
		$cs.Dispose()
		$sr.Dispose()
		Write-Debug "Disposing $mmf, $cs, $sr"
	}
	return $content
}

$NvConfig = Get-NvConfig
$HttpClient = New-Object System.Net.Http.HttpClient
$NvEndpointInstantReplay = "ShadowPlay/v.1.0/InstantReplay/Enable"
$NvEndpointShadowplayLaunch = '/ShadowPlay/v.1.0/Launch'

# $BaseUri = "127.0.0.1:$($NvConfig.port)"



function Build-NvUri {
	param (
		[Parameter(Mandatory = $false)]
		$UriArgs = @{}
	)
	$ctor = @{
		Port = $NvConfig.port
		Host = "127.0.0.1"
	} + $UriArgs
	$UriBuilder = [System.UriBuilder]$ctor
	return $UriBuilder
}

function Assert-NvConfig {
	param([scriptblock]$assertion)
	if ($NvConfig) {
		return & $assertion
	}
	else {
		throw "Config not available"
	}
}

function Build-NvRequest {
	param (
		[Parameter(Mandatory = $false)]
		$RequestArgs = @{},
		[Parameter(Mandatory = $false)]
		$UriArgs = $null,
		[Parameter(Mandatory = $false)]
		$Content
	)
	
	if ($Content) {
		if ($Content -is [string]) {
			$Content = [System.Net.Http.StringContent]$Content
		}
	}

	$UriArgs = Build-NvUri $UriArgs

	return Assert-NvConfig {
		$ctor = @{
			RequestUri = $UriArgs.Uri.ToString()
		} + $RequestArgs
		$request = [System.Net.Http.HttpRequestMessage] $ctor
		$request.Headers.Add('X_LOCAL_SECURITY_COOKIE', $NvConfig.secret)
		$request.Content = $Content
		return $request
	}
}

function Read-NvResponse {
	param (
		[System.Net.Http.HttpResponseMessage]$Response
	)
	
	$content = $Response.Content.ReadAsStringAsync().Result
	return $content
}

function Get-NvInstantReplay {
	
	$req = Build-NvRequest -RequestArgs @{Method = "Get" } `
		-UriArgs @{Path = $NvEndpointInstantReplay }

	$res = $HttpClient.Send($req)
	Write-Debug "$res"
	$res2 = Read-NvResponse $res
	return $res2
}

function Set-NvInstantReplay {
	param (
		$Status
	)
	
	$req = Build-NvRequest -RequestArgs @{Method = "Post" } `
		-UriArgs @{Path = $NvEndpointInstantReplay } `
		-Content "{`"status`": $($Status.ToString().ToLower())}"

	Write-Debug "$req"
	$res = $HttpClient.Send($req)
	Write-Debug "$res"
	$res2 = Read-NvResponse $res
	return $res2
}

function Get-NvShadowplay {
	
	$req = Build-NvRequest -RequestArgs @{Method = "Get" } `
		-UriArgs @{Path = $NvEndpointShadowplayLaunch }

	$res = $HttpClient.Send($req)
	Write-Debug "$res"
	$res2 = Read-NvResponse $res
	return $res2

}

function Set-NvShadowplay {
	param (
		$Status
	)
	
	$req = Build-NvRequest -RequestArgs @{Method = "Post" } `
		-UriArgs @{Path = $NvEndpointShadowplayLaunch } `
		-Content "{`"launch`": $($Status.ToString().ToLower())}"

	Write-Debug "$req"
	$res = $HttpClient.Send($req)
	Write-Debug "$res"
	$res2 = Read-NvResponse $res
	return $res2
}