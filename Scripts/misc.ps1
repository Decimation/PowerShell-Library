
function global:typeof { param($x) return $x.GetType() }



function Set-Constant {
	
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string][ValidateNotNullOrEmpty()]$Name,

		[Parameter(Mandatory = $true, Position = 1)]
		[char][ValidateSet('=')]$Link,

		[Parameter(Mandatory = $true, Position = 2)]
		[object][ValidateNotNullOrEmpty()]$Mean,

		[Parameter(Mandatory = $false)]
		[string]$Surround = 'script',
		
		[Parameter(Mandatory = $false, Position = 4)]
		$vis = [System.Management.Automation.SessionStateEntryVisibility]::Public
	)

	Set-Variable -n $name -val $mean -opt ReadOnly -s $surround -Visibility $vis -ErrorAction Ignore
}

function Set-Readonly {
	
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string][ValidateNotNullOrEmpty()]$Name,

		[Parameter(Mandatory = $true, Position = 1)]
		[char][ValidateSet('=')]$Link,

		[Parameter(Mandatory = $true, Position = 2)]
		[object][ValidateNotNullOrEmpty()]$Mean,

		[Parameter(Mandatory = $false)]
		[string]$Surround = 'script',

		[Parameter(Mandatory = $false, Position = 4)]
		$vis = [System.Management.Automation.SessionStateEntryVisibility]::Public
	)

	Set-Variable -n $name -val $mean -opt ReadOnly -s $surround -Visibility $vis -ErrorAction Ignore
}

Set-Alias readonly Set-Readonly
Set-Alias const Set-Constant






$WinMedia = "$env:WINDIR\Media"

$script:WinSoundPlayer = ([System.Media.SoundPlayer]::new())


function Start-WinSound {
	param (
		$x
	)

	$p = "$WinMedia\$x"
	if (-not (Resolve-Path $p -ErrorAction Ignore)) {
		$p = Get-ChildItem "$p.*"
		Write-Debug "$p"
	}
	$script:WinSoundPlayer.SoundLocation = ($p)
	$script:WinSoundPlayer.Play()
}

function Stop-WinSound {
	$script:WinSoundPlayer.Stop()
}

function Get-SubstringBetween {
	param([string]$value, [string] $a, [string] $b)

	$posA = $value.IndexOf($a, [System.StringComparison]::Ordinal)
	$posB = $value.LastIndexOf($b, [System.StringComparison]::Ordinal)

	$inv = -1

	if ($posA -eq $inv -or $posB -eq $inv) {
		return [String]::Empty
	}

	$adjustedPosA = $posA + $a.Length
	$x = $adjustedPosA -ge $posB ? [String]::Empty : $value[$adjustedPosA..$posB]
	$sz = [string]::new([char[]]$x)
	
	if ($sz.EndsWith($b)) {
		$sz = $sz.Substring(0, $sz.LastIndexOf($b))
	}
	return $sz
}


function Convert-ObjToHashTable {
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[pscustomobject]$Object
	)

	$HashTable = @{}
	$ObjectMembers = Get-Member -InputObject $Object -MemberType *Property
	foreach ($Member in $ObjectMembers) {
		$HashTable.$($Member.Name) = $Object.$($Member.Name)
	}
	return $HashTable
}

function obj_cast {
	param (
		$a, $t
	)

	return [System.Management.Automation.LanguagePrimitives]::ConvertTo($a, ($t))
}

function Convert-ObjFromHashTable {
	param (
		[parameter(Mandatory = $true)]$x,
		[parameter(Mandatory = $false)]$t
	)
	
	$o = New-Object pscustomobject
	$o | Add-Member $x
	
	if ($t) {
		$o = obj_cast $o $t
	}

	return $o
}