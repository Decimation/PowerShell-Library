
function global:typeof { param($pred) return $pred.GetType() }



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
		$pred
	)

	$p = "$WinMedia\$pred"
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
	$pred = $adjustedPosA -ge $posB ? [String]::Empty : $value[$adjustedPosA..$posB]
	$sz = [string]::new([char[]]$pred)
	
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
		[parameter(Mandatory = $true)]$pred,
		[parameter(Mandatory = $false)]$t
	)
	
	$o = New-Object pscustomobject
	$o | Add-Member $pred
	
	if ($t) {
		$o = obj_cast $o $t
	}

	return $o
}



#region


function adb {

	$argBuf = [System.Collections.Generic.List[string]]::new()
	$argBuf.AddRange([string[]]$args)

	Write-Debug "Original args: $($argBuf -join ',')`n"

	switch ($argBuf[0]) {
		

		Default {}
	}

	Write-Debug "Final args: $($argBuf -join ',')"

	adb.exe @argBuf
}

function Adb-QPush {
	
	param($f, [parameter(Mandatory = $false)] $d = 'sdcard/')

	if ($f -is [array]) {
		$f | ForEach-Object -Parallel { 
			adb.exe push "$_" $using:d
		}
	}

}

function Adb-QPull {
	$r = Adb-GetItems @args
	Write-Verbose "$($r.Length)"
	$r | ForEach-Object -Parallel { 
		adb.exe pull $_
	}
	
}

function Adb-GetItems {
	[CmdletBinding()]
	param (
		[Parameter()]
		$pred,
		[parameter(Mandatory = $false)]$type = 'f'
	)

	$a = (("shell find $pred -type $type" -split ' '))

	return adb @a
}

#endregion


#region
<# function New-Chunks {
	[CmdletBinding()]
	param (
		[parameter(ParameterSetName = 'ArrayGroups', Mandatory = $true)]
		[parameter(ParameterSetName = 'ArrayMaxSize', Mandatory = $true)]
		[array]$Array,
		[parameter(ParameterSetName = 'HashtableGroups', Mandatory = $true)]
		[parameter(ParameterSetName = 'HashtableMaxSize', Mandatory = $true)]
		[hashTable]$HashTable,
		[parameter(ParameterSetName = 'ArrayMaxSize', Mandatory = $true)]
		[parameter(ParameterSetName = 'HashtableMaxSize', Mandatory = $true)]
		[int32]$MaxSize,
		[parameter(ParameterSetName = 'HashtableGroups', Mandatory = $true)]
		[parameter(ParameterSetName = 'ArrayGroups', Mandatory = $true)]
		[int32]$Groups
	)
	begin {
		if ($PSCmdlet.ParameterSetName -like 'Array*') {
			$ItemCount = $array.Count
		}
		elseif ($PSCmdlet.ParameterSetName -like 'Hashtable*') {
			​
			$ItemCount = $Hashtable.Count
			$Keys = [array]$Hashtable.Keys
		}
		if ($PSCmdlet.ParameterSetName -like '*MaxSize') {
			$Groups = [Math]::Ceiling( $ItemCount / $MaxSize)
			$step = [Math]::Floor( $ItemCount / $Groups)
		}
		elseif ($PSCmdlet.ParameterSetName -like '*Groups') {
			$step = [Math]::Ceiling( $ItemCount / $Groups)
		}
	}
	process {
		for ($i = 0; $i -lt $ItemCount; $i += $step) {
			if ($PSCmdlet.ParameterSetName -like 'Array*') {
				, $array[$i..($i + $step - 1)]
			}
			elseif ($PSCmdlet.ParameterSetName -like 'Hashtable*') {
				$tmpHashTable = @{}
				foreach ($Key in $Keys[$i..($i + $step - 1)]) {
					$tmpHashTable.Add($Key , $Hashtable[$key])
				}
				$tmpHashTable.Clone()
			}
		}
	}
	end {
	}
}

function Split-ArrayInChunks_UsingArrayList($inArray, $numberOfChunks) {

	$Lists = @{}
	$count = 0 

	# populate 
	0..($numberOfChunks - 1) | ForEach-Object {
		$Lists[$_] = New-Object System.Collections.ArrayList
	}

	$inArray | ForEach-Object { 
		[void]$Lists[$count % $numberOfChunks].Add($_); 
		$count++ 
	}

	Write-Host 'Number of arryList:'$Lists.Count
	Write-Host 'Number of items in first arryList:' $Lists[0].Count
	return $Lists
} #>
#endregion
