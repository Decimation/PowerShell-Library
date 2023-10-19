using namespace System.Windows
using namespace System.Collections.Specialized
using namespace System.Collections
Add-Type -Assembly PresentationCore

function Set-ClipboardDataObject {
	[OutputType([Void])]
	param(
		[Parameter(Mandatory=$true, Position=0)]
		[Object]
		$Value
	)

	[Clipboard]::SetDataObject($Value)
}

function Get-ClipboardDataObject {
	[OutputType([Object])]
	param()

	return [Clipboard]::GetDataObject()
}

function Set-ClipboardText {
	[OutputType([Void])]
	param(
		[Parameter(Mandatory=$true, Position=0)]
		[String]
		$Text
	)

	[Clipboard]::SetText($Text)
}




function Get-FileDropList {
	[OutputType([StringCollection])]
	param()

	return [Clipboard]::GetFileDropList()
	
}