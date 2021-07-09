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
		[Parameter(Mandatory=$true)]	[string]	$repoName,
		[Parameter(Mandatory=$true)]	[string]	$fileName,
		[Parameter(Mandatory=$true)]	[string]	$localFile,
		[Parameter(Mandatory=$false)]	[string]	$name,
		[Parameter(Mandatory=$false)]	[string]	$token,
		[Parameter(Mandatory=$false)]	[string]	$commitMsg
	)

	
	$nameEnv = [System.Environment]::GetEnvironmentVariable("GH_NAME")
	AutoAssign([ref]$name) -val $nameEnv

	$tokenEnv = [System.Environment]::GetEnvironmentVariable("GH_TOKEN")
	AutoAssign([ref]$token) -val $tokenEnv

	$commitMsgDef = "Update"
	AutoAssign([ref]$commitMsg) -val $commitMsgDef
	
	Write-Host "Name: $name"
	Write-Host "Token: $token"

	$url = "https://api.github.com/repos/$name/$repoName/contents/$fileName"

	$buf = Invoke-WebRequest $url -Method GET | ConvertFrom-Json -AsHashtable
	$sha = $buf["sha"].ToString()

	$base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($localFile))

	$headers = @{
		Accept = "application/vnd.github.v3+json"
	}

	$body = @{
		"sha" = "$sha"
		"message" = "$commitMsg"
		"content" = "$base64string"
	} | ConvertTo-Json

	$stoken = ConvertTo-SecureString -AsPlainText $token
	
	$res = Invoke-RestMethod -Uri $url -Method PUT -Body $body -Headers $headers -Authentication OAuth -Token $stoken

	
	Write-Host "Completed"
	
	#wh $res | Format-Table

	# Send-GitHubFile "PowerShell-Library" "Modules\Android.psm1" "C:\Users\Deci\Documents\PowerShell\Modules\Android.psm1"
	# Send-GitHubFile "PowerShell-Library" "Microsoft.PowerShell_profile.ps1" "C:\Users\Deci\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

	return $res
}


function Get-Symbols {
	param (
		[Parameter(Mandatory=$true)][string]$s,
		[Parameter(Mandatory=$false)][string]$dest
	)

	if (!($dest)) {
		$dest = Get-Location
	}
	
	symchk "$s" /s SRV*$dest*http://msdl.microsoft.com/download/symbols
}

function Stop-Task {
	param (
		[Parameter(Mandatory=$true)][string]$name
	)

	taskkill /f /im $name
}

function Invoke-Batch {
	param (
		[Parameter(Mandatory=$true)][string]$s
	)
	return (cmd /c $s)
}

readonly Q_DEST = "H:\Archives & Backups\(Unsorted)"

Set-Variable -Scope Global -Name SIG -Value @"
[DllImport("urlmon.dll", CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = false)]
		public static extern int FindMimeFromData(IntPtr pBC,
												[MarshalAs(UnmanagedType.LPWStr)] string pwzUrl,
												[MarshalAs(UnmanagedType.LPArray, ArraySubType = UnmanagedType.I1, SizeParamIndex = 3)]
												byte[] pBuffer,
												int cbSize,
												[MarshalAs(UnmanagedType.LPWStr)] string pwzMimeProposed,
												int dwMimeFlags,
												out IntPtr mout,
												int dwReserved);

"@

function Id-File {
	param (
		[Parameter(Mandatory=$true)][string]$s
	)
	#Add-Type -MemberDefinition $sig -Name Win32 -Namespace PInvoke -Using PInvoke,System.Text;
	$b=[System.IO.File]::ReadAllBytes($s)
	$r = [System.IntPtr]::Zero
	#$r = [System.Text.StringBuilder]::new()
	#$r = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(1024)
	$p=[PInvoke.Win32]::FindMimeFromData([System.IntPtr]::Zero,[System.IntPtr]::Zero,$b,$b.Length,$null,0,[ref]$r,0)

	Write-Host $p
	Write-Host $r
	$r2=[System.Runtime.InteropServices.Marshal]::PtrToStringUni($r)
Write-Host $r2
}

function QMove {
	param (
		[Parameter(Mandatory=$true)][string]$s,
		[Parameter(Mandatory=$false)][string]$d
	)
	
	if (!($d)) {
		$d = $Q_DEST
	}

	Move-Item "$s" "$d"

	Write-Information "Moved $s to $d"
}