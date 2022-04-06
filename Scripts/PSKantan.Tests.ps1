
BeforeAll {
	Import-Module PSKantan
	
}

Describe 'Main' {

	It 'Integer' {
		IsInteger 1 | Should -Be $true
	}
	It 'Real' {
		IsReal 3.1 | Should -Be $true
	}
	It 'Parallel' {
		if (-not (Adb-GetDevices)) {
			return $true
		}

		$x = Adb-GetItems 'sdcard/download'
		$x2 =	$x | Invoke-Parallel -ScriptBlock {
			Adb-GetItem $_ -ErrorAction SilentlyContinue
		} -ImportVariables -Quiet -ErrorAction SilentlyContinue
		
		$x2.Length | Should -BeGreaterThan 0
		
	}
	It 'Conversion' {
		
	}
}