# using namespace System.;
# using namespace System.IO.Pipes;
# using assembly 'C:\Program Files\dotnet\shared\Microsoft.NETCore.App\8.0.2\System.IO.Pipes.dll'

# BEGIN: FILEPATH: Untitled-1

# Create a named pipe for IPC communication0
function Test-Pipe {
	param (
		$pipeName
	)
	
	$pipePath = "\\.\pipe\$pipeName"
	return Test-Path $pipePath
}

$pipeName = "mpsv"

if (Test-Pipe $pipeName) {
	return	
}

try {
	$pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream ($pipeName, [System.IO.Pipes.PipeDirection]::InOut)

	Write-Output "$pipeServer"

	Write-Output "Waiting"
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
	
	$pipeReader.Dispose()
	$pipeServer.Dispose()
	Write-Output "Disconnected"
}
