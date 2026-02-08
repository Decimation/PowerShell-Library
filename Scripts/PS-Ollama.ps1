function Get-OllamaResponse {
	param (
		[Parameter(Mandatory = $false)]
		$Model,
		
		[Parameter(Mandatory = $true)]
		$Prompt,

		[Parameter()]
		[ValidateSet("json", "text")]
		$Format = "json",
		
		[Parameter()]
		[switch]
		$Stream
	)
	
	$req = @{
		'prompt' = $Prompt
		'format' = $Format
		'stream' = $Stream.IsPresent
	}
	
	if ($Model) {
		$req['model'] = $Model
	}
	
	$body = ($req | ConvertTo-Json -Depth 3)

	Write-Debug "Request: $req"
	Write-Debug "Request Body: $body"

	$res = Invoke-WebRequest -Uri "http://localhost:11434/api/generate" -Method POST `
		-Body $body `
		-ContentType "application/json" `
		-SkipHeaderValidation

	return $res
}