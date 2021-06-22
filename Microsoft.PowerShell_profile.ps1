
function Push-All {
	param(
        [Parameter(Mandatory=$false)][string]$dest
    )
	
	$cd = Get-Location

	if (!($dest)) {
		$dest="sdcard/"
	}

	#$dest = $(If ($args.Count -eq 0) {"sdcard/"} Else {$dest})

	Write-Host $cd files to $dest

	Get-ChildItem | ForEach-Object {
		if ([System.IO.File]::Exists($_)) {
			adb push $_ $dest
		}
	}
}

function Pull-All-Filter {
	<#[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs')]#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
	param (
		[Parameter(Mandatory=$true)][string]$src,
		[Parameter(Mandatory=$true)][string]$f
	)
	foreach ($x in (adb shell ls $src | Select-String $f)) {
		adb pull "$src/$x"
	}
}
function Input-Tap {
	<#[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs')]#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
	param (
		[Parameter(Mandatory=$true)][long]$x,
		[Parameter(Mandatory=$true)][long]$y
	)
	adb shell input tap $x $y
}

<#function kuroba {
	
	Input-Tap 1360 235 
	Input-Tap 1043 1244
	Input-Tap 530 2223 
	Input-Tap 500 1137 
	Input-Tap 1190 250

	

}#>

<# adb shell input swipe 50 1330 1370 1430 10 #>

<#function DecodeBase64Image {
    param (
        [Parameter(Mandatory=$true)]
        [String]$ImageBase64
    )
    # Parameter help description
    $ObjBitmapImage = New-Object System.Windows.Media.Imaging.BitmapImage #Provides a specialized BitmapSource that is optimized for loading images using Extensible Application Markup Language (XAML).
    $ObjBitmapImage.BeginInit() #Signals the start of the BitmapImage initialization.
    $ObjBitmapImage.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($ImageBase64) #Creates a stream whose backing store is memory.
    $ObjBitmapImage.EndInit() #Signals the end of the BitmapImage initialization.
    $ObjBitmapImage.Freeze() #Makes the current object unmodifiable and sets its IsFrozen property to true.
}#>

function Get-Translation {
	param (
		[Parameter(Mandatory=$true)][string]$x,
		[Parameter(Mandatory=$true)][string]$y
	)

	$cmd = "from googletrans import * `n" +`
	"tmp=Translator().translate('$x',dest='$y')`n" +`
	"print(tmp.text)`n" +`
	"print(tmp.pronunciation)"

	python -c $cmd

	Write-Host

	$cmd2 = "from translatepy import * `n" +`
	"tmp2=Translator().translate('$x','$y')`n" +`
	"print(tmp2)"

	python -c $cmd2
}


function Prompt {
	<#$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = [Security.Principal.WindowsPrincipal] $identity
	$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator#>
  
	<#$(if (Test-Path variable:/PSDebugContext) { '[DBG]: ' }
	  elseif($principal.IsInRole($adminRole)) { "[ADMIN]: " }
	  else { '' }
	) + 'PS ' + $(Get-Location) +
	  $(if ($NestedPromptLevel -ge 1) { '>>' }) + '> '#>

	
	Write-Host ("PS " + "[$(Get-Date -Format "HH:mm:ss")] " + $(Get-Location) +">") -NoNewLine
	return " "

  }

#Remove-Module -Name Index
Import-Module "$Home\Documents\PowerShell\Modules\Index.psm1"

# .
# &