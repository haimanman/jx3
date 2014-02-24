<?php
// pre_release to update version, generate new info.ini
// usage: pre_release.php <beta|stable> [version]
$type = isset($_SERVER['argv'][1]) ? $_SERVER['argv'][1] : 'beta';
$version_str = isset($_SERVER['argv'][2]) ? $_SERVER['argv'][2] : '';

// --- CONFIG ---
$name = 'HM, JX3 Plug-in';
$desc = 'Large number of convenient PVP plugs! -- hmm@buliantai --';
$pver = '1.0';
$required = array('HM.lua', 'HM_Compatible.lua');
$tag_version = "\tdwVersion = ";
$tag_build = "\tszBuildDate = \"";

// --- UPDATE HM.lua ---
echo "updating version & build date ... ";
$version = 0;
$body = file_get_contents('src/HM.lua');
if (($pos1 = strpos($body, $tag_version)))
{
	$pos1 = $pos1 + strlen($tag_version);
	$pos2 = strpos($body, ',', $pos1);
	if ($version_str != '' && preg_match('/(\d+)\.(\d+)\.(\d+)(?:b(\d+))?/', $version_str, $match))
	{
		// man-version
		$version = (intval($match[1]) << 24) | (intval($match[2]) << 16);
		$min = intval($match[3]);
		$version |= ($min << 8);
		if ($type == 'beta' || $type === 'alpha')
		{
			$version += (isset($match[4]) ? intval($match[4]) : 1);
			if (($min & 1) == 0)
				$version += 0x100;
		}
		else
		{
			if (($min & 1) == 1)
				$version += 0x100;
		}
	}
	else
	{
		// auto-version
		$version = hexdec(substr($body, $pos1, $pos2 - $pos1));
		$min = ($version >> 8) & 0xff;
		if ($type == 'beta' || $type === 'alpha')
		{
			$version += 1;
			if (($min & 1) == 0)
				$version += 0x100;
		}
		else
		{
			$version -= ($version & 0xff);
			$version += ($min & 1) ? 0x100 : 0x200;
		}
	}
	$body = substr_replace($body, sprintf('0x%x', $version), $pos1, $pos2 - $pos1);
}
$version_str = sprintf('%d.%d.%d', $version>>24, ($version>>16)&0xff, ($version>>8)&0xff);
if ($version & 0xff)
	$version_str .= sprintf('%s%d', $type === 'alpha' ? 'a' : 'b', $version & 0xff);
if (($pos1 = strpos($body, $tag_build)))
{
	$pos1 = $pos1 + strlen($tag_build);
	$pos2 = strpos($body, '"', $pos1);
	date_default_timezone_set('Asia/Shanghai');
	$body = substr_replace($body, date('Ymd'), $pos1, $pos2 - $pos1);
}
file_put_contents('src/HM.lua', $body);
echo " $version_str\n";

// --- UPDATE VERSION file ---
echo "creating new VERSION ...\n";
file_put_contents('VERSION', $version_str);

// --- UPDATE info.ini ---
echo "updating info.ini ...\n";
$info = "[HM]\r\nname=$name($version_str)\r\ndesc=$desc\r\nversion=$pver\r\ndefault=1\r\n";
$files1 = glob("src/*.lua");
$files2 = glob("lab/*.lua");
sort($files1);
sort($files2);
$files = array_merge($files1, $files2);
for ($i = 0; $i < count($required); $i++)
{
	$info .= "lua_{$i}=interface\\HM\\src\\{$required[$i]}\r\n";
}
foreach ($files as $file)
{
	// remove HM_Taoguan.lua (unless 1.10-2.20)
	$date = date('n') * 100 + intval(date('j'));
	if ($file === 'lab/HM_Taoguan.lua' && ($date < 110 || $date > 220))
		continue;
	if (in_array(basename($file), $required)) continue;
	$file = str_replace('/', '\\', $file);
	$info .= "lua_{$i}=interface\\HM\\$file\r\n";
	$i++;
}
file_put_contents('info.ini', $info);

// --- UPDATE README.md ---
if ($type !== 'alpha')
{
	echo "updateing README.md ...\n";
	$body = preg_replace('#HM\-(.+?)\.zip#', 'HM-' . $version_str . '.zip', file_get_contents('README.md'));
	file_put_contents('README.md', $body);
}
