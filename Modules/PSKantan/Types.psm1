
# region Objects

function Get-SubstringBetween {
	param ([string]$value,
		[string]$a,
		[string]$b)
	
	$posA = $value.IndexOf($a, [System.StringComparison]::Ordinal)
	$posB = $value.LastIndexOf($b, [System.StringComparison]::Ordinal)
	
	$inv = -1
	
	if ($posA -eq $inv -or $posB -eq $inv) {
		return [String]::Empty
	}
	
	$adjustedPosA = $posA + $a.Length
	$pred = $adjustedPosA -ge $posB ? [String]::Empty: $value[$adjustedPosA .. $posB]
	$sz = [string]::new([char[]]$pred)
	
	if ($sz.EndsWith($b)) {
		$sz = $sz.Substring(0, $sz.LastIndexOf($b))
	}
	return $sz
}

function Convert-ObjToHashTable {
	[CmdletBinding()]
	[outputtype([hashtable])]
	param (
		[parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[pscustomobject]$Object
	)
	process {
		$HashTable = @{
		}
		$ObjectMembers = Get-Member -InputObject $Object -MemberType *Property
		foreach ($Member in $ObjectMembers) {
			$HashTable.$($Member.Name) = $Object.$($Member.Name)
		}
		return $HashTable
	}
	
	
}

function Convert-Obj {
	param (
		$a,
		$t
	)
	return [System.Management.Automation.LanguagePrimitives]::ConvertTo($a, ($t2))
}

Set-Alias cast Convert-Obj
Set-Alias conv Convert-Obj

function Convert-ObjFromHashTable {
	param (
		[parameter(Mandatory = $true)]
		$pred,
		[parameter(Mandatory = $false)]
		$t
	)
	
	$o = New-Object pscustomobject
	$o | Add-Member $pred
	
	if ($t) {
		$o = Convert-Obj $o $t
	}
	
	return $o
}



function Get-Bytes {
	[outputtype([byte[]])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline)]
		$x,
		[Parameter(Mandatory = $false)]
		$encoding
	)

	process {

		$isStr = $x -is [string]
		$info1 = @()
		$rg = @()
		
		if ($isStr) {
			if (!($encoding)) {
				$encoding = [System.Text.Encoding]::Default
			}
			
			$info1 += $encoding.EncodingName
			$rg = $encoding.GetBytes($x)
		}
		else {
			$rg = [System.BitConverter]::GetBytes($x)
		}
		
		<# Write-Host "[$($typeX.Name)]" -NoNewline -ForegroundColor Yellow
		
		if ($info1.Length -ne 0) {
			Write-Host ' | ' -NoNewline
			Write-Host "$($info1 -join ' | ')" -NoNewline
		}
		
		Write-Host ' | ' -NoNewline
		Write-Host "$x" -ForegroundColor Cyan #>
		
		return $rg
	}
}



function IsReal {
	param (
		$x
	)
	$c = typecodeof $x
	
	return IsInRange -a $c -max ([System.TypeCode]::Decimal) -min ([System.TypeCode]::Single)
}

function IsInteger {
	param (
		$x
	)
	$c = typecodeof $x
	
	return IsInRange -a $c -max ([System.TypeCode]::UInt64) -min ([System.TypeCode]::SByte)
}

function IsInRange {
	param (
		$a,
		$min,
		$max,
		[switch]$noninc
	)

	
	if ($noninc) {
		return $a -gt $min -and $a -lt $max
	}
	return $a -ge $min -and $a -le $max
}

function IsNumeric {
	param (
		$x
	)
	return (IsInteger $x) -or (IsReal $x)
}


function typename {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		$x
	)

	process {

		$y = ($x | Get-Member)[0].TypeName
		return $y
	}
	
}

function typeof {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		$x
	)
	process {

		#return [type]::GetType((typename $x))
		return $x.GetType()
	}
}

function typecodeof {
	param ($x)
	$t = $x.GetType()
	$c = [type]::GetTypeCode($t)
	return $c
}

# endregion




# region Collection operations

function Flatten($a) {
	, @($a | ForEach-Object { $_ })
}

function Get-Difference {
	param (
		[Parameter(Mandatory = $true)]
		[object[]]$a,
		[Parameter(Mandatory = $true)]
		[object[]]$b
	)
	
	return $b | Where-Object {
		($a -notcontains $_)
	}
}

function Get-Intersection {
	param (
		[Parameter(Mandatory = $true)]
		[object[]]$a,
		[Parameter(Mandatory = $true)]
		[object[]]$b
	)
	return Compare-Object $a $b -PassThru -IncludeEqual -ExcludeDifferent
}

function Get-Union {
	param (
		[Parameter(Mandatory = $true)]
		[object[]]$a,
		[Parameter(Mandatory = $true)]
		[object[]]$b
	)
	return Compare-Object $a $b -PassThru -IncludeEqual
}

function New-List {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		$x
	)
	return New-Object "System.Collections.Generic.List[$x]"
}


function Linq-Where {
	
	param (
		[Parameter(ValueFromPipeline)]
		$Value,
		[Parameter()]
		$Predicate
	)
	process {
		$Predicate = [func[object, bool]]$Predicate
		return Invoke-Linq -Name "Where" $Value ([System.Func[object, bool]] $Predicate)
	}
}

function Linq-First {
	param (
		[Parameter(ValueFromPipeline)]
		$Value,
		[Parameter()]
		$Predicate
	)
	process {
		return Invoke-Linq -Name "First" $Value ([System.Func[object, bool]] $Predicate)
	}
}

function Linq-Select {
	param (
		[Parameter(ValueFromPipeline)]
		$Value,
		[Parameter()]
		$Predicate
	)
	process {
		$Predicate = [func[object, object]]$Predicate
		return Invoke-Linq -Name "Select" $Value ([System.Func[object, bool]] $Predicate)

	}
}

function Linq-TakeLast {
	param($Value, $Count)
	return Invoke-Linq -Name "TakeLast" -Value $Value -Arg1 $Count
}

function Invoke-Linq {
	param (
		$Value, $Name, $Arg1
	)
	[System.Linq.Enumerable]::$Name($Value, $Arg1)
}

function New-RandomArray {
	param (
		[Parameter(Mandatory = $true)]
		[int]$c
	)
	$rg = [byte[]]::new($c)
	$rand = [System.Random]::new()
	$rand.NextBytes($rg)
	return $rg
}

# endregion
