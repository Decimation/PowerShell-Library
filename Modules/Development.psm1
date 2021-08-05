<#
# Development utilities
#>


<#
.Description
Pushes a file to the specified GitHub repository
#>
function Send-GitHubFile {
	

	#https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod?view=powershell-7.1

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]	[string]	$repoName,
		[Parameter(Mandatory = $true)]	[string]	$fileName,
		[Parameter(Mandatory = $true)]	[string]	$localFile,
		[Parameter(Mandatory = $false)]	[string]	$name,
		[Parameter(Mandatory = $false)]	[string]	$token,
		[Parameter(Mandatory = $false)]	[string]	$commitMsg
	)

	
	$nameEnv = [System.Environment]::GetEnvironmentVariable('GH_NAME')
	AutoAssign([ref]$name) -val $nameEnv

	$tokenEnv = [System.Environment]::GetEnvironmentVariable('GH_TOKEN')
	AutoAssign([ref]$token) -val $tokenEnv

	$commitMsgDef = 'Update'
	AutoAssign([ref]$commitMsg) -val $commitMsgDef
	
	Write-Host "Name: $name"
	Write-Host "Token: $token"

	$url = "https://api.github.com/repos/$name/$repoName/contents/$fileName"

	$buf = Invoke-WebRequest $url -Method GET | ConvertFrom-Json -AsHashtable
	$sha = $buf['sha'].ToString()

	$base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($localFile))

	$headers = @{
		Accept = 'application/vnd.github.v3+json'
	}

	$body = @{
		'sha'     = "$sha"
		'message' = "$commitMsg"
		'content' = "$base64string"
	} | ConvertTo-Json

	$stoken = ConvertTo-SecureString -AsPlainText $token
	
	$res = Invoke-RestMethod -Uri $url -Method PUT -Body $body -Headers $headers -Authentication OAuth -Token $stoken

	
	Write-Host 'Completed'
	
	#wh $res | Format-Table

	# Send-GitHubFile "PowerShell-Library" "Modules\Android.psm1" "C:\Users\Deci\Documents\PowerShell\Modules\Android.psm1"
	# Send-GitHubFile "PowerShell-Library" "Microsoft.PowerShell_profile.ps1" "C:\Users\Deci\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

	return $res
}


function Get-Symbols {
	param (
		[Parameter(Mandatory = $true)][string]$s,
		[Parameter(Mandatory = $false)][string]$dest
	)

	if (!($dest)) {
		$dest = Get-Location
	}
	
	symchk "$s" /s SRV*$dest*http://msdl.microsoft.com/download/symbols

	
	
	$p = [System.IO.Path]::GetFileNameWithoutExtension($s)
	Rename-Item "$p.pdb" "$p-1"
	Move-Item $(Get-ChildItem $(Get-ChildItem "$p-1")) .
	Remove-Item pingme.txt
	Remove-Item "$p-1" -Recurse
}


function ForceKill {
	param (
		[Parameter(Mandatory = $true)][string]$name
	)

	Stop-Process (Get-Process $name).Id
	#taskkill /f /im $name
}
Set-Alias -Name fk -Value ForceKill

function Invoke-Batch {
	param (
		[Parameter(Mandatory = $true)][string]$s
	)
	return (cmd /c $s)
}

function Get-FileType {
	param (
		[Parameter(Mandatory = $true)][string]$f
	)

	$s = ".$($f.Split('.')[-1])"

	$r = Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$s"

	$p = $r | so -ExpandProperty '(Default)'

	
	#$r | Format-Table -Wrap
	#$p | Format-Table -Wrap	

	$r2 = Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$p"

	#$r2 | Format-Table -Wrap

	#wh ($r2 | Select-Object -ExpandProperty "(Default)")

	Write-Host $r.'(default)'
	Write-Host $r.'Content Type'
	Write-Host $r.'PerceivedType'
	Write-Host $r2.'(default)'

	return $r
}



$global:Q_DEST = 'H:\Archives & Backups\(Unsorted)'

function QMove {
	param (
		[Parameter(Mandatory = $true)][string]$s,
		[Parameter(Mandatory = $false)][string]$d
	)
	
	if (!($d)) {
		$d = $Q_DEST
	}

	Move-Item "$s" "$d"

	Write-Information "$s -> $d"
}



# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
	param($commandName, $wordToComplete, $cursorPosition)
	dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}