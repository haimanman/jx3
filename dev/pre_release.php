<?php
// pre_release to update version, generate new info.ini
$type = isset($_SERVER['argv'][1]) ? $_SERVER['argv'][1] : 'beta';

// --- CONFIG ---
$name = 'HM, JX3 Plug-in';
$desc = 'A large number of convenient PVP plugs! -- hmm@buliantai --';
$pver = '0.8';
$required = array('HM.lua', 'HM_Compatible.lua');
$tag_version = "\tdwVersion = ";
$tag_build = "\tszBuildDate = \"";

// --- UPDATE HM.lua ---
echo "updating version & build date ...\n";
$version = 0;
$body = file_get_contents('src/HM.lua');
if (($pos1 = strpos($body, $tag_version)))
{
	$pos1 = $pos1 + strlen($tag_version);
	$pos2 = strpos($body, ',', $pos1);
	$version = hexdec(substr($body, $pos1, $pos2 - $pos1));
	$min = ($version >> 8) & 0xff;
	if ($type == 'beta')
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
	$body = substr_replace($body, sprintf('0x%x', $version), $pos1, $pos2 - $pos1);
}
if (($pos1 = strpos($body, $tag_build)))
{
	$pos1 = $pos1 + strlen($tag_build);
	$pos2 = strpos($body, '"', $pos1);
	date_default_timezone_set('Asia/Shanghai');
	$body = substr_replace($body, date('Ymd'), $pos1, $pos2 - $pos1);
}
file_put_contents('src/HM.lua', $body);
$version_str = sprintf('%d.%d.%d', $version>>24, ($version>>16)&0xff, ($version>>8)&0xff);
if ($version & 0xff)
	$version_str .= sprintf('b%d', $version & 0xff);

// --- UPDATE VERSION file ---
echo "creating new VERSION ...\n";
file_put_contents('VERSION', $version_str);

// --- UPDATE info.ini ---
echo "updating info.ini ...\n";
$info = "[HM]\r\nname=$name($version_str)\r\ndesc=$desc\r\nversion=$pver\r\ndefault=1\r\n";
$files = glob("src/*.lua");
sort($files); 
reset($files);
for ($i = 0; $i < count($required); $i++)
{
	$info .= "lua_{$i}=interface\\HM\\src\\{$required[$i]}\r\n";
}
foreach ($files as $file)
{
	if (in_array(basename($file), $required)) continue;
	$file = str_replace('/', '\\', $file);
	$info .= "lua_{$i}=interface\\HM\\$file\r\n";
	$i++;
}
file_put_contents('info.ini', $info);

// --- UPDATE README.md ---
echo "updateing README.md ...\n";
$body = preg_replace('#HM\-(.+?).zip#', 'HM-' . $version_str . '.zip', file_get_contents('README.md'));
file_put_contents('README.md', $body);
