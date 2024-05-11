# socat.ps1
# usage: socat.ps1 <Pipe-name> <Message>
$socketName = $args[0]
$message = $args[1]
Write-Host "Sending message to $socketName"

$npipeClient = New-Object System.IO.Pipes.NamedPipeClientStream('.', $socketName, [System.IO.Pipes.PipeDirection]::InOut, ` 
	[System.IO.Pipes.PipeOptions]::None, [System.Security.Principal.TokenImpersonationLevel]::Impersonation)

$pipeReader = $pipeWriter = $null

try {
	$npipeClient.Connect()
	$pipeReader = New-Object System.IO.StreamReader($npipeClient)
	$pipeWriter = New-Object System.IO.StreamWriter($npipeClient)
	$pipeWriter.AutoFlush = $true

	$pipeWriter.WriteLine($message)

	while (($data = $pipeReader.ReadLine()) -ne $null) {
		$data
	}
}
catch {
	"An error occurred that could not be resolved."
}
finally {
	$npipeClient.Dispose()
}