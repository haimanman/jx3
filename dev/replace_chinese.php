<?php
// replace string: "..." => _L["..."], string.format("..." => _L("..."
// reverse string: _L["..."] => "...", _L("..." => string.format("..."
$reverse = (isset($_SERVER['argv'][1]) && $_SERVER['argv'][1] == '-r');
echo "begin to " . ($reverse ? "replace _L() code to raw chinese\n" : "replace chinese to _L() code\n");
echo "  loading lang data ... ";

// load replace data
$lines = @file('HM_0Base/lang/zhcn.jx3dat');
if (!$lines)
{
	echo "failed to load zhcn.jx3dat\n";
	exit(0);
}
$replace1 = $replace2 = array();
foreach ($lines as $line)
{
	if (preg_match('/\["(.+?)"\] = "(.+?)",/', $line, $match))
	{
		if (strpos($match[2], '%') !== false)
		{
			$k = 'string.format("' . $match[2] . '"';
			$v = '_L("' . $match[1] . '"';
			if ($reverse)
				$replace1[$v] = $k;
			else
				$replace1[$k] = $v;
		}
		$k = '"' . $match[2] . '"';
		$v = '_L["' . $match[1] . '"]';
		if ($reverse)
			$replace2[$v] = $k;
		else
			$replace2[$k] = $v;
	}
}
echo " OK, " . count($replace2) . " strings\n";


// replace all lua files
$files = glob("HM_*/*.lua");
foreach ($files as $file)
{
	echo "  replacing $file ...\n";
	$data = file_get_contents($file);
	$data = strtr($data, $replace1);
	$data = strtr($data, $replace2);
	if (!$reverse)
	{
		// check _L[_L["..."]]
		while (($pos1 = strpos($data, '_L[_L["')) !== false 
			&& ($pos2 = strpos($data, '"]]', $pos1)) !== false)
		{
			$data2 = substr($data, 0, $pos1);
			$data2 .= substr($data, $pos1 + 3, $pos2 - $pos1 - 1);
			$data2 .= substr($data, $pos2 + 3);
			$data = $data2;
		}
		// check _L(_L["..."]
		while (($pos1 = strpos($data, '_L(_L["')) !== false
			&& ($pos2 = strpos($data, '"]', $pos1)) !== false)
		{
			$data2 = substr($data, 0, $pos1 + 3);
			$data2 .= substr($data, $pos1 + 6, $pos2 - $pos1 - 5);
			$data2 .= substr($data, $pos2 + 2);
			$data = $data2;
		}
	}
	file_put_contents($file, $data);
}
echo "finished!\n";
