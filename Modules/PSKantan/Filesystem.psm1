# region Filesystem IO


function XRemove {
	param ($x)
	#todo
	
	takeown /F $x /R
	sudo rm -Force $x
}

Set-Alias xrm XRemove


function OpenHere {
	Start-Process $(Get-Location)
}

function Find-Item {
	[CmdletBinding()]
	param (
		
		[Parameter(Mandatory = $true)]
		[string]$s,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.CommandTypes]$c = 'All', 
		[switch]$pw = $false
	)
	
	$a = (Get-Command $s -CommandType $c).Path

	if ((Test-Command 'whereis' Application) -and (-not $a)) {
		return (whereis.exe $s)
	}
		
	return $a
}
	

Set-Alias whereitem Find-Item

function Search-InFiles {
	param (
		# Content filter
		[Parameter(Mandatory)]
		$ContentFilter,

		# Path filter
		[parameter(Mandatory = $false)]
		$PathFilter,

		# Path
		[parameter(Mandatory = $false)]
		$Path = '.',

		# Depth
		[Parameter(Mandatory = $false)]
		$Depth = 1,
		
		[switch]$Strict
	)
	
	if (-not $Strict) {
		$PathFilter = "*$PathFilter*"
	}
	
	$r = Get-ChildItem -Path $Path -File -Filter "$PathFilter" `
		-Recurse -Depth $Depth -ErrorAction SilentlyContinue

	$r2 = $r | ForEach-Object {
		Get-Content $_ | Select-String $ContentFilter
	}

	return $r2
}

Set-Alias search Search-InFiles

# endregion


function New-TempFile {
	return [System.IO.Path]::GetTempFileName()
}

function New-RandomFile {
	param (
		[Parameter(Mandatory = $true)]
		[long]$length,
		[Parameter(Mandatory = $false)]
		[string]$file,
		[switch][bool]$nullFile
	)
	
	if (!($file)) {
		$file = $(New-TempFile)
	}
	
	if ((Test-Path $file)) {
		return $false;
	}
	
	$buf = & {
		fsutil file createnew $file $length
	}
	Write-Verbose "$buf"
	
	if (($nullFile)) {
		return;
	}
	
	$fs = [System.IO.File]::OpenWrite($(Resolve-Path $file))
	$rg = [byte[]]$(New-RandomArray $length)
	$fs.Write($rg, 0, $rg.Length)
	$fs.Flush()
	$fs.Close()
	$fs.Dispose()
	
	return $true;
}


function Get-FileBytes {
	param (
		[Parameter(Mandatory = $true)]
		[string]$file
	)
	$b = [System.IO.file]::ReadAllBytes($file)
	return $b
}


function Get-RegistryFileType {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Update
	)
	
	$s = ".$($Update.Split('.')[-1])"
	$r = Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$s"
	$p = $r | Select-Object -ExpandProperty '(Default)'
	$r2 = Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$p"
	
	Write-Host $r.'(default)'
	Write-Host $r.'Content Type'
	Write-Host $r.'PerceivedType'
	Write-Host $r2.'(default)'
	
	return $r
}



<#function Get-FileMetadata {
	
	<#
	Adapted from Get-FolderMetadata by Ed Wilson

	https://devblogs.microsoft.com/scripting/list-music-file-metadata-in-a-csv-and-open-in-excel-with-powershell/
	https://web.archive.org/web/20201111223917/https://gallery.technet.microsoft.com/scriptcenter/get-file-meta-data-function-f9e8d804
	>
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$folder,
		[Parameter(Mandatory = $false)]
		[string]$PathFilter
		
	)
	
	$rg = New-List 'psobject'
	$a = 0
	$objShell = New-Object -ComObject Shell.Application
	$objFolder = $objShell.namespace($folder)
	
	$items = $objFolder.items()
	
	if (($PathFilter)) {
		$items = $items | Where-Object {
			$_.Name -contains $PathFilter
		}
	}
	
	foreach ($File in $items) {
		$FileMetaData = New-Object PSOBJECT
		for ($a; $a -le 266; $a++) {
			if ($objFolder.getDetailsOf($File, $a)) {
				$hash += @{
					$($objFolder.getDetailsOf($objFolder.items, $a)) =
					$($objFolder.getDetailsOf($File, $a))
				}
				$FileMetaData | Add-Member $hash
				$hash.clear()
			}
		}
		$a = 0
		#$FileMetaData
		
		$rg.Add($FileMetaData)
		
	}
	
	return $rg
}#>


function Get-SanitizedFilename {
	param (
		$origFileName
	)
	$invalids = [System.IO.Path]::GetInvalidFileNameChars()
	$newName = [String]::Join('_', $origFileName.Split($invalids, 
			[System.StringSplitOptions]::RemoveEmptyEntries)).TrimEnd('.')
	
	return $newName
}
