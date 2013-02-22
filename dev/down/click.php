<?php
// click times
$file = 'clicks.inc.php';
$clicks = file_exists($file) ? include($file) : array();
$version = $_SERVER['QUERY_STRING'];
if (!empty($version) && strpos($version, '/') === false 
	&& file_exists('./HM-' . $version . '.zip'))
{
	if (!is_array($clicks))
		$clicks = array();
	if (!isset($clicks[$version]))
		$clicks[$version] = 1;
	else
		$clicks[$version]++;
	$content = '<?php return ' . var_export($clicks, true) . ';';
	file_put_contents($file, $content);
}
echo 'OK';
