function Search-Package {
	param (
		$Name
	)
	
	& scoop search $Name
	
}