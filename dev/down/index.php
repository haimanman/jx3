<?php
// 下载页, download page
$files = unserialize(file_get_contents('../sync/release.dat'));
$clicks = file_exists('clicks.inc.php') ? include('clicks.inc.php') : array();
$list = array();
foreach ($files as $file)
{
	$file['file'] = 'HM-' . $file['version'] . '.zip';
	if (!file_exists($file['file'])) continue;
	$file['click'] = isset($clicks[$file['version']]) ? number_format($clicks[$file['version']]) : '-';
	$file['size'] = sprintf('%.1f KB', filesize($file['file']) / 1024);
	$list[] = $file;
}
$title = '《剑网3》、海鳗插件 - 下载';
?>
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<link rel="shortcut icon" type="image/x-icon" href="favicon.ico">
<title><?php echo $title; ?></title>
<style type="text/css">
body { font-size: 14px; font-family: Tahoma; }
a { color: #07c; }
li { padding: 0; margin: 0 0 0 10px; }
li h2 { font-size: 18px; margin-bottom: 10px; }
li h2 small { font-size: 14px; color: #666; font-weight: normal; }
li p { margin: 0 0 20px 0; }
p.offical { font-size: 16px; margin-left: 24px; }
dl {
  position: absolute; left: 660px; top: 10px;
  background: #e1e2e6; color: #717375; padding: 10px;
  border-radius: 5px; -webkit-border-radius: 5px;
  text-align: center;
}
dt, dd { padding: 0; margin: 0; }
dt img { width: 147px; height: 147px; }
</style>
<script type="text/javascript" language="javascript">
var XmlHttp = false;
function SaveClick(v)
{
	if (!XmlHttp)
	{
		try { XmlHttp = new ActiveXObject('Msxml1.XMLHTTP'); }
		catch (e)
		{
			try { XmlHttp = new ActiveXObject('Microsoft.XMLHTTP'); }
			catch (e) { XmlHttp = false; }
		}
		if (!XmlHttp && (typeof XMLHttpRequest != 'undefined'))
			XmlHttp = new XMLHttpRequest();
	}
	if (XmlHttp)
	{
		XmlHttp.open('GET', 'click.php?' + v, true);
		XmlHttp.send(null);
	}
	return true;
}
</script>
</head>
<body>
<h1><?php echo $title; ?></h1>
<p class="offical">
官方网站：<a href="http://haimanchajian.com">http://haimanchajian.com</a>，<a href="https://github.com/haimanman/jx3/">源码@github</a><br />
其它工具：<a href="http://haimanchajian.com/repack/">PAK 文件清理工具</a>，<a href="JX3HM-2.1.exe">JX3HM-2.1.exe</a>（安史之乱风格：自动更新、功能筛选）
</p>
<ol>
  <?php foreach($list as $file): ?>
  <li>
    <h2>
	  <a href="<?php echo $file['file']; ?>" onclick="return SaveClick('<?php echo $file['version']; ?>');"><?php echo $file['file']; ?></a>
	  <small>(<?php echo $file['date']; ?>，<?php echo $file['size']; ?>，<?php echo $file['click']; ?> Dowloads)</small>
	</h2>
	<p>
	  <?php echo nl2br($file['log']); ?>
	</p>
  </li>
  <?php endforeach; ?>
</ol>
<dl id="qrcode">
  <dt><img src="../qrcode.jpg" alt="微信二维码" /></dt>
  <dd>【剑三查询】<br />微信扫描即可添加关注</dd>
</dl>
</body>
</html>
