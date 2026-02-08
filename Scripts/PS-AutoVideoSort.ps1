$Script:Extensions = @(
	".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm", ".mpeg", ".mpg", ".3gp"
)

function Get-UnknownItems {
	param (
		$Path
	)

	$items = Get-ChildItem -Path $Path -Recurse -File | Where-Object {
		$ext = $_.Extension.ToLower()
		$Script:Extensions -ccontains $ext
	}

	return $items
}

function Is-UntitledFile {
	param (
		[string]$FileName
	)

	# Define regex patterns for "untitled" file names
	$patterns = @(
		'^VID_\d{5}',         		 # Matches "VID_?????" (e.g., VID_12345)
		'^\d{4}-\d{2}-\d{2}', 		 # Matches "YYYY-MM-DD" (e.g., 2025-10-02)
		'^[a-zA-Z0-9_-]{1,10}$' 	 # Matches short, nondescript names (1-10 characters)
	)

	# Check if the file name matches any of the patterns
	foreach ($pattern in $patterns) {
		if ($FileName -match $pattern) {
			return $true
		}
	}

	return $false
}