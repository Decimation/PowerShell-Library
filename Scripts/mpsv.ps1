# using namespace System.;
# using namespace System.IO.Pipes;
# using assembly 'C:\Program Files\dotnet\shared\Microsoft.NETCore.App\8.0.2\System.IO.Pipes.dll'

# BEGIN: FILEPATH: Untitled-1

# Create a named pipe for IPC communication0

<#     $pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream ($pipeName, [System.IO.Pipes.PipeDirection]::InOut)
 #>


<# 
$x=New-Object 'System.IO.Pipes.NamedPipeClientStream'($env:COMPUTERNAME,"\\.\pipe\mpsv",[System.IO.Pipes.PipeDirection]::InOut,
[System.IO.Pipes.PipeOptions]::None,[System.Security.Principal.TokenImpersonationLevel]::Impersonation)
#>

param (
	[string]$pipeName = "mpsv",
	[switch]$srv
)

$pipePath = "\\.\pipe\$pipeName"
Write-Output $pipePath

function RunMpsv {
	
	param (
		$pipeServer
	)

	try {

		# Write-Output "$pipeServer"

		Write-Output "Waiting on $using:pipePath $pipeServer"

		# Connect to the named pipe
		
		$pipeServer.WaitForConnection()
		Write-Output "Connected"

		$pipeReader = New-Object System.IO.StreamReader($pipeServer)
		$script:pipeWriter = New-Object System.IO.StreamWriter($pipeServer)
		$pipeWriter.AutoFlush = $true

	
		while ($line -ne "exit") {
			$pipeWriter.WriteLine("Received: $line")
			$line = $pipeReader.ReadLine()
			Write-Output "Received: $line"
		}
	}
	finally {
		Write-Output "Disconnecting..."
		$pipeServer.Disconnect()
		$pipeReader.Dispose()
		Write-Output "Disconnected"
	}
}

if ($srv) {

	$pipeServer2 = New-Object System.IO.Pipes.NamedPipeServerStream ($pipePath, [System.IO.Pipes.PipeDirection]::InOut, 1, [System.IO.Pipes.PipeTransmissionMode]::Message)
	
	Start-Job -ScriptBlock $function:RunMpsv -ArgumentList $pipeServer2 
	
}