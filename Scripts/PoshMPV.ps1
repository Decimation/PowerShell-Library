function Get-Bookmarklog {
	[CmdletBinding()]
	[OutputType([hashtable[]])]
	param (
		[Parameter()]
		$File
	)

	#	[Sunday / December 10/12/2017 04:01:22] L:\Movies\Star Wars\Star.Wars.Episode.IV.A.New.Hope.1977.1080p.BluRay.X264-AMIABLE\Star.Wars.Episode.IV.1977.1080p.BluRay.X264-AMIABLE.mkv | length=2223.763 | time=2223.763

	$lines = Get-Content $File
	$entries = [hashtable[]]@()


	$lines | ForEach-Object {
		$eb = $_.IndexOf(']')
		$dt = $_.Substring(1, $eb - 1).Trim()
		$fnLenTime = $_.Substring($eb + 1).Trim().Split(' | ')
		$fn = $fnLenTime[0]
		$len = $fnLenTime[1]
		$time = $fnLenTime[2]

		$entry = @{
			Date   = $dt
			File   = $fn
			Length = $len
			Time   = $time
		}

		$entries += $entry
	}

	return $entries
}