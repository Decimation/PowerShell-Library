
function Get-RawVideoUrl {
	param ($u,
		$k)
	$id = Get-VideoId $u
	$u2 = "https://www.googleapis.com/drive/v3/files/$id`?key=$k&alt=media"
	return $u2
}

function Get-VideoId {
	param ($u)
	$id = $u.Split('d/')[1].Split('/view')[0]
	return $id
}
function Get-VideoMetadata {
	param ($u,
		$k)
	
	$id = Get-VideoId $u
	$u2 = "https://www.googleapis.com/drive/v3/files/$id`?key=$k&fields=*"
	
	return (Invoke-WebRequest -Uri $u2)
	
}