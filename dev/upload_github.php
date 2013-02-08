<?php
// upload file to github
$auth_user = @file_get_contents($_SERVER['HOME'] . '/.githubuser');
if ($auth_user === false)
{
	echo "auth user of github not found!\n";
	exit(-1);
}
$auth_user = trim($auth_user);
$version = trim(file_get_contents('VERSION'));

// file to upload
$file = 'dist/HM-' . $version . '.zip';
if (!file_exists($file))
{
	echo "release pack file not found!\n";
	exit(-1);
}

// get update msg
$desc = date('Y/m/d');
$lines = array();
exec('git log -5 --pretty="format:%s"', $lines);
for ($i = 0; $i < count($lines); $i++)
{
	$line = trim($lines[$i]);
	if ($line == 'Release ' . $version) continue;
	if (!strncmp($lines[$i], 'Release ', 8)) break;
	$desc .= ', ' . trim($lines[$i]);
}
if ($i == count($lines))
	$desc .= ' ...';

// step.1 (get resource)
$url = 'https://api.github.com/repos/haimanman/jx3/downloads';
$data = json_encode(array(
  'name' => basename($file),
  'size' => filesize($file),
  'description' => $desc,
  'content_type' => 'application/zip',
));
$header = 'Authorization: Basic ' . base64_encode($auth_user);
$header .= "\r\nContent-Type: application/x-www-form-urlencoded";
$context = stream_context_create(array(
	'http' => array(
		'method' => 'POST',
		'header' => $header,
		'follow_location' => 0,
		'max_redirects' => 1,
		'ignore_errors' => 1,
		'content' => $data,
	),
));
$res = file_get_contents($url, false, $context);
if ($res === false)
{
	echo "alloc download resource failed\n";
	exit(-1);
}
$res = (array) json_decode($res);

// step.2 (upload file to s3 server), using curl
$data = '';
$boundary = substr(md5(microtime()), 0, 8);
$fields = array(
	'key' => $res['path'],
	'acl' => $res['acl'],
	'success_action_status' => 201,
	'Filename' => $res['name'],
	'AWSAccessKeyId' => $res['accesskeyid'],
	'Policy' => $res['policy'],
	'Signature' => $res['signature'],
	'Content-Type' => $res['mime_type'],
);
foreach ($fields as $key => $value)
{
	$data .= "--{$boundary}\r\nContent-Disposition: form-data; name=\"{$key}\"\r\n\r\n{$value}\r\n";
}
$data .= "--{$boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{$res['name']}\"\r\nContent-Type: {$res['mime_type']}\r\nContent-Transfer-Encoding: binary\r\n\r\n";
$data .= file_get_contents($file) . "\r\n";
$data .= "--{$boundary}--\r\n";

// do request
$context = stream_context_create(array(
	'http' => array(
		'method' => 'POST',
		'header' => 'Content-Type: multipart/form-data; boundary=' . $boundary,
		'follow_location' => 0,
		'max_redirects' => 1,
		'ignore_errors' => 1,
		'content' => $data,
	),
));
$res2 = file_get_contents($res['s3_url'], false, $context);
if ($res2 === false)
{
	@file_get_contents($url . '/' . $res['id'], false, stream_context_create(array('http' => array(
		'method' => 'DELETE',
		'header' => 'Authorization: Basic ' . base64_encode($auth_user),
		'follow_location' => 0,
		'max_redirects' => 1,
		'ignore_errors' => 1,
	))));
	echo "upload file failed\n";
	exit(-1);
}
echo "OK!\n";
