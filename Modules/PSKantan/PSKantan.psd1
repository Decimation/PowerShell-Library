
@{
	RootModule            = 'PSKantan.psm1'
	ModuleVersion         = '1.0'
	Author                = 'Decimation'
	Copyright             = '(C) 2021 Read Stanton. All rights reserved.'
	PowerShellVersion     = '5.1'
	ProcessorArchitecture = 'Amd64'
	FunctionsToExport     = '*'
	CmdletsToExport       = '*'
	VariablesToExport     = '*'
	AliasesToExport       = '*'

	NestedModules         = @('Android', 'Editing', 'Formatting', 'Utilities')
	#ModuleList            = @('Android')
}