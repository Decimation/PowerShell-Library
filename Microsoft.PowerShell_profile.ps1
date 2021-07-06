<#
# Profile
#>

<#----------------------------------------------------------------------------#>

function Set-Constant {
	<#
	  .SYNOPSIS
		  Creates constants.
	  .DESCRIPTION
		  This function can help you to create constants so easy as it possible.
		  It works as keyword 'const' as such as in C#.
	  .EXAMPLE
		  PS C:\> Set-Constant a = 10
		  PS C:\> $a += 13
  
		  There is a integer constant declaration, so the second line return
		  error.
	  .EXAMPLE
		  PS C:\> const str = "this is a constant string"
  
		  You also can use word 'const' for constant declaration. There is a
		  string constant named '$str' in this example.
	  .LINK
		  Set-Variable
		  About_Functions_Advanced_Parameters
	#>
	[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$true, Position=0)]
	  [string][ValidateNotNullOrEmpty()]$Name,
  
	  [Parameter(Mandatory=$true, Position=1)]
	  [char][ValidateSet("=")]$Link,
  
	  [Parameter(Mandatory=$true, Position=2)]
	  [object][ValidateNotNullOrEmpty()]$Mean,
  
	  [Parameter(Mandatory=$false)]
	  [string]$Surround = "script"
	)
  
	Set-Variable -n $name -val $mean -opt Constant -s $surround
}

Set-Alias const Set-Constant

<#----------------------------------------------------------------------------#>

$DeciModules = @{
	Index		=	"$Home\Documents\PowerShell\Modules\Index.psm1";
	Android		=	"$Home\Documents\PowerShell\Modules\Android.psm1";
	Win32		=	"$Home\Documents\PowerShell\Modules\Win32.psm1";
	Formatting	=	"$Home\Documents\PowerShell\Modules\Formatting.psm1";
}


<#
.Description
Loads Deci modules
#>
function Import-Deci {
	
	foreach ($x in $DeciModules.Values) {
		Import-Module $x
	}
}



<#
.Description
Unloads Deci modules
#>
function Remove-Deci {
	foreach ($x in $DeciModules.Keys) {
		Remove-Module $x
	}
}



<#
.Description
Reloads Deci modules
#>
function Update-Deci {
	Remove-Deci
	Import-Deci
	
}



<#----------------------------------------------------------------------------#>

Import-Deci

<#----------------------------------------------------------------------------#>

function Get-Translation {
	param (
		[Parameter(Mandatory=$true)][string]$x,
		[Parameter(Mandatory=$true)][string]$y
	)

	$cmd = "from googletrans import * `n" +`
	"tmp = Translator().translate('$x', dest='$y')`n" +`
	"print('{0} ({1})'.format(tmp.text, tmp.pronunciation))`n"
	

	$out1 = (python -c $cmd)

	$cmd2 = "from translatepy import * `n" +`
	"tmp2 = Translator().translate('$x', '$y')`n" +`
	"print(tmp2)"

	$out2 = (python -c $cmd2)

	Write-Host "[#1] $out1"
	Write-Host "[#2] $out2"
}



function Prompt {
	Write-Host ("PS " + "[$(Get-Date -Format "HH:mm:ss")] " + $(Get-Location) +">") -NoNewLine
	return " "
}






function AutoAssign([ref]$name, $val) {
	
	#Write-Host $name.ToString() -NoNewline

	if (!($name.HasValue) -or ($name -eq $null)) {
		#wd "assigning"
		$name.Value = $val
	}
	
	#wd "-> $name"
}

$GH_TOKEN = "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"


function Send-GitHubFile {
	<#
	PUT https://api.github.com/repos/Decimation/PowerShell-Library/contents/Microsoft.PowerShell_profile.ps1
	Authorization: token 
	Accept: application/vnd.github.v3+json

	{
		"sha": "90d7d9ca8b2b0eae3c7ac76973e30051359a89ee",
		"message":"my commit message",
		"content":"PCMNCiMgUHJvZmlsZQ0KIz4NCg0KPCMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIz4NCg0KZnVuY3Rpb24gR2V0LVRyYW5zbGF0aW9uIHsNCglwYXJhbSAoDQoJCVtQYXJhbWV0ZXIoTWFuZGF0b3J5PSR0cnVlKV1bc3RyaW5nXSR4LA0KCQlbUGFyYW1ldGVyKE1hbmRhdG9yeT0kdHJ1ZSldW3N0cmluZ10keQ0KCSkNCg0KCSRjbWQgPSAiZnJvbSBnb29nbGV0cmFucyBpbXBvcnQgKiBgbiIgK2ANCgkidG1wID0gVHJhbnNsYXRvcigpLnRyYW5zbGF0ZSgnJHgnLCBkZXN0PSckeScpYG4iICtgDQoJInByaW50KCd7MH0gKHsxfSknLmZvcm1hdCh0bXAudGV4dCwgdG1wLnByb251bmNpYXRpb24pKWBuIg0KCQ0KDQoJJG91dDEgPSAocHl0aG9uIC1jICRjbWQpDQoNCgkkY21kMiA9ICJmcm9tIHRyYW5zbGF0ZXB5IGltcG9ydCAqIGBuIiArYA0KCSJ0bXAyID0gVHJhbnNsYXRvcigpLnRyYW5zbGF0ZSgnJHgnLCAnJHknKWBuIiArYA0KCSJwcmludCh0bXAyKSINCg0KCSRvdXQyID0gKHB5dGhvbiAtYyAkY21kMikNCg0KCVdyaXRlLUhvc3QgIlsjMV0gJG91dDEiDQoJV3JpdGUtSG9zdCAiWyMyXSAkb3V0MiINCn0NCg0KDQoNCmZ1bmN0aW9uIFByb21wdCB7DQoJV3JpdGUtSG9zdCAoIlBTICIgKyAiWyQoR2V0LURhdGUgLUZvcm1hdCAiSEg6bW06c3MiKV0gIiArICQoR2V0LUxvY2F0aW9uKSArIj4iKSAtTm9OZXdMaW5lDQoJcmV0dXJuICIgIg0KfQ0KDQpmdW5jdGlvbiBTZXQtQ29uc3RhbnQgew0KCTwjDQoJICAuU1lOT1BTSVMNCgkJICBDcmVhdGVzIGNvbnN0YW50cy4NCgkgIC5ERVNDUklQVElPTg0KCQkgIFRoaXMgZnVuY3Rpb24gY2FuIGhlbHAgeW91IHRvIGNyZWF0ZSBjb25zdGFudHMgc28gZWFzeSBhcyBpdCBwb3NzaWJsZS4NCgkJICBJdCB3b3JrcyBhcyBrZXl3b3JkICdjb25zdCcgYXMgc3VjaCBhcyBpbiBDIy4NCgkgIC5FWEFNUExFDQoJCSAgUFMgQzpcPiBTZXQtQ29uc3RhbnQgYSA9IDEwDQoJCSAgUFMgQzpcPiAkYSArPSAxMw0KICANCgkJICBUaGVyZSBpcyBhIGludGVnZXIgY29uc3RhbnQgZGVjbGFyYXRpb24sIHNvIHRoZSBzZWNvbmQgbGluZSByZXR1cm4NCgkJICBlcnJvci4NCgkgIC5FWEFNUExFDQoJCSAgUFMgQzpcPiBjb25zdCBzdHIgPSAidGhpcyBpcyBhIGNvbnN0YW50IHN0cmluZyINCiAgDQoJCSAgWW91IGFsc28gY2FuIHVzZSB3b3JkICdjb25zdCcgZm9yIGNvbnN0YW50IGRlY2xhcmF0aW9uLiBUaGVyZSBpcyBhDQoJCSAgc3RyaW5nIGNvbnN0YW50IG5hbWVkICckc3RyJyBpbiB0aGlzIGV4YW1wbGUuDQoJICAuTElOSw0KCQkgIFNldC1WYXJpYWJsZQ0KCQkgIEFib3V0X0Z1bmN0aW9uc19BZHZhbmNlZF9QYXJhbWV0ZXJzDQoJIz4NCglbQ21kbGV0QmluZGluZygpXQ0KCXBhcmFtKA0KCSAgW1BhcmFtZXRlcihNYW5kYXRvcnk9JHRydWUsIFBvc2l0aW9uPTApXQ0KCSAgW3N0cmluZ11bVmFsaWRhdGVOb3ROdWxsT3JFbXB0eSgpXSROYW1lLA0KICANCgkgIFtQYXJhbWV0ZXIoTWFuZGF0b3J5PSR0cnVlLCBQb3NpdGlvbj0xKV0NCgkgIFtjaGFyXVtWYWxpZGF0ZVNldCgiPSIpXSRMaW5rLA0KICANCgkgIFtQYXJhbWV0ZXIoTWFuZGF0b3J5PSR0cnVlLCBQb3NpdGlvbj0yKV0NCgkgIFtvYmplY3RdW1ZhbGlkYXRlTm90TnVsbE9yRW1wdHkoKV0kTWVhbiwNCiAgDQoJICBbUGFyYW1ldGVyKE1hbmRhdG9yeT0kZmFsc2UpXQ0KCSAgW3N0cmluZ10kU3Vycm91bmQgPSAic2NyaXB0Ig0KCSkNCiAgDQoJU2V0LVZhcmlhYmxlIC1uICRuYW1lIC12YWwgJG1lYW4gLW9wdCBDb25zdGFudCAtcyAkc3Vycm91bmQNCn0NCg0KU2V0LUFsaWFzIGNvbnN0IFNldC1Db25zdGFudA0KDQoNCg0KPCMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIz4NCg0KJERlY2lNb2R1bGVzID0gQHsNCglJbmRleAkJPQkiJEhvbWVcRG9jdW1lbnRzXFBvd2VyU2hlbGxcTW9kdWxlc1xJbmRleC5wc20xIjsNCglBbmRyb2lkCQk9CSIkSG9tZVxEb2N1bWVudHNcUG93ZXJTaGVsbFxNb2R1bGVzXEFuZHJvaWQucHNtMSI7DQoJV2luMzIJCT0JIiRIb21lXERvY3VtZW50c1xQb3dlclNoZWxsXE1vZHVsZXNcV2luMzIucHNtMSI7DQoJRm9ybWF0dGluZwk9CSIkSG9tZVxEb2N1bWVudHNcUG93ZXJTaGVsbFxNb2R1bGVzXEZvcm1hdHRpbmcucHNtMSI7DQp9DQoNCg0KPCMNCi5EZXNjcmlwdGlvbg0KTG9hZHMgRGVjaSBtb2R1bGVzDQojPg0KZnVuY3Rpb24gSW1wb3J0LURlY2kgew0KCQ0KCWZvcmVhY2ggKCR4IGluICREZWNpTW9kdWxlcy5WYWx1ZXMpIHsNCgkJSW1wb3J0LU1vZHVsZSAkeA0KCX0NCn0NCg0KDQoNCjwjDQouRGVzY3JpcHRpb24NClVubG9hZHMgRGVjaSBtb2R1bGVzDQojPg0KZnVuY3Rpb24gUmVtb3ZlLURlY2kgew0KCWZvcmVhY2ggKCR4IGluICREZWNpTW9kdWxlcy5LZXlzKSB7DQoJCVJlbW92ZS1Nb2R1bGUgJHgNCgl9DQp9DQoNCg0KDQo8Iw0KLkRlc2NyaXB0aW9uDQpSZWxvYWRzIERlY2kgbW9kdWxlcw0KIz4NCmZ1bmN0aW9uIFVwZGF0ZS1EZWNpIHsNCglSZW1vdmUtRGVjaQ0KCUltcG9ydC1EZWNpDQoJDQp9DQoNCg0KPCMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIz4NCg0KSW1wb3J0LURlY2kNCg=="
	}
	#>


	#[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]	[string]	$repoName,
		[Parameter(Mandatory=$true)]	[string]	$fileName,
		[Parameter(Mandatory=$true)]	[string]	$localFile,
		[Parameter(Mandatory=$false)]	[string]	$name,
		[Parameter(Mandatory=$false)]	[string]	$token
	)


	AutoAssign([ref]$token, [System.Environment]::GetEnvironmentVariable("GH_TOKEN"))
	AutoAssign([ref]$name, [System.Environment]::GetEnvironmentVariable("GH_NAME"))

	Write-Host "Name: $name `n"


	$url = "https://api.github.com/repos/$name/$repoName/contents/$fileName"

	$buf = Invoke-WebRequest $url -Method GET | ConvertFrom-Json -AsHashtable
	$sha = $buf["sha"].ToString()

	$base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($localFile))

	$headers = @{
		Accept = "application/vnd.github.v3+json"
	}

	$body = @{
		"sha" = "$sha"
		"message" = "msg"
		"content" = "$base64string"
	} | ConvertTo-Json

	$stoken = ConvertTo-SecureString -AsPlainText $token
	
	$res = Invoke-RestMethod -Uri $url -Method PUT -Body $body -Headers $headers -Authentication OAuth -Token $stoken

	wh $res
}
