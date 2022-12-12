function nuke {
	param (
		$i,
		$o,
		[Parameter(Mandatory = $false)]
		$c
	)

	if ($c) {

	}
	$arg = @(
		'-i', $i
		'-color_primaries', 'bt2020',
		'-color_trc', 'bt709',
		'-colorspace', 'bt2020_ncl',
		'-color_range', 'pc',
		'-vf', "convolution='0 -1 0 -1 5 -1 0 -1 0:0 -1 0 -1 5 -1 0 -1 0:0 -1 0 -1 5 -1 0 -1 0:0 -1 0 -1 5 -1 0 -1 0',scale=trunc(iw/2):trunc(ih/2)",
		'-af', "acrusher=.1:1:64:0:log",
		'-y',
		$o
	)

	ffmpeg.exe @arg
}