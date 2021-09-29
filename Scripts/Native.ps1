$Signature = @'
[DllImport("user32.dll")]
public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);
'@

#Add the SendMessage function as a static method of a class
$SendMessageFunc = Add-Type -MemberDefinition $Signature -Name 'Win32SendMessage' -Namespace Win32Functions -PassThru

function SendMessage {
	param (
		[Parameter(Mandatory = $true)]$name,
		[Parameter(Mandatory = $true)]$k
	)

	$p = (Get-Process $name).MainWindowHandle

	$SendMessageFunc::SendMessage($p, 0x0100, $k, 0x002C0001)
	$SendMessageFunc::SendMessage($p, 0x0101, $k, 0x002C0001)
}