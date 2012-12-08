<?php
// update zhcn languages
$lang = isset($_SERVER['argv'][1]) ? $_SERVER['argv'][1] : 'zhcn';

// load exists languages
$lines = @file('lang/' . $lang . '.lua');
if (!$lines)
{
	echo "Bad Lang: $lang\n";
	exit(0);
}
$key = '';
$data = $data2 = $data3 = array();
foreach ($lines as $no => $line)
{
	$line = trim($line);
	if (!strncmp($line, '-- ', 3) && strpos($line, '.lua') !== false)
	{
		$key = substr($line, 3, -3);
		$data[$key] = array();
	}
	else if ($key == '')
		continue;
	else if (preg_match('/\["(.+?)"\] = "(.+?)(?<!\\\\)"/', $line, $match))
	{
		$k = $match[1];
		$v = $match[2];
		$data[$key][$k] = $v;
		if (isset($data2[$k]))
			echo "-- conflict english '$k' in line $no\n";	
		$data2[$k] = false;
		if ($lang == 'zhcn')
			$data3[$v] = $k;
	}
}

// load new data from lua files
$files = glob("src/*.lua");
foreach ($files as $file)
{
	$body = file_get_contents($file);
	// exists langs
	preg_match_all('/_L[\[\(]"(.+?)(?<!\\\\)"/', $body, $matches);
	foreach ($matches[1] as $tmp)
	{
		if (!isset($data2[$tmp]))
			$data[$file][$tmp] = "";
		$data2[$tmp] = true;	// marked to keep
	}
	// scan new chinese string
	if ($lang == 'zhcn')
	{
		preg_match_all('/"(.*?)(?<!\\\\)"/', $body, $matches);
		foreach ($matches[1] as $tmp)
		{
			if (!preg_match('/[\x81-\xfe]/', $tmp)) continue;
			if (!isset($data3[$tmp]))
			{
				$key = 'TODO#' . (count($data2) + 1);
				$data2[$key] = true;
				$data[$file][$key] = $tmp;
			}
			else
			{
				$data2[$data3[$tmp]] = true;
			}
		}
	}
}

// re-output the result
echo "-- language data ($lang) updated at " . date('Y/m/d H:i:s') . "\r\n";
echo "data = {\r\n";
foreach ($data as $file => $lang)
{
	if (count($lang) == 0) continue;
	echo "\t -- $file --\r\n";
	foreach ($lang as $k => $v)
	{
		$v = $v === "" ? "nil" : '"' . $v . '"';
		echo "\t" . ($data2[$k] === false ? "--" : "") . "[\"$k\"] = $v,\r\n";
	}
}
echo "}\r\n";
