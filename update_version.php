<?php
// update gh-pages index.html
$v = trim(file_get_contents("VERSION"));
$b = file_get_contents("index.html");
$b = preg_replace("#HM-.+?\.zip#", "HM-$v.zip", $b);
$b = preg_replace("#HM-.+?，#", "HM-{$v}，", $b);
$b = preg_replace("#date-->.+?\)#", "date-->" . date("Y/m/d") . ")", $b);
file_put_contents("index.html", $b);
