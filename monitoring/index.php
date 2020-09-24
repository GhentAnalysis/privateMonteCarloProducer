<html>
<head>
<title><?php $user = get_current_user(); echo str_replace('/user/'.$user.'/public_html','',getcwd()); ?></title>
<style type='text/css'>
body {
    font-family: "Helvetica", sans-serif;
    font-size: 9pt;
    line-height: 10.5pt;
}
h1 {
    font-size: 14pt;
    margin: 0.5em 1em 0.2em 1em;
    text-align: left;
    float: right;
}
div.bar {
    display: block;
    float: left;
    margin: 0.5em 1em 0.2em 1em;
    padding: 10px;
    color: #29407C;
    background: white;
    text-align: center;
    border: 1px solid #29407C;
    border-radius: 5px;
}
div.barEmpty {
    color: #ccc;
    border: 1px solid #ccc;
}
a.bar {
    display: block;
    float: left;
    margin: 0.5em 1em 0.2em 1em;
    padding: 10px;
    color: white;
    background: #29407C;
    text-align: center;
    border: 1px solid #29407C;
    border-radius: 5px;
}
a.bar:hover {
    background-color: #4CAF50;
    color: white;
}
div.list {
    font-size: 13pt;
    margin: 0.5em 1em 1.2em 1em;
    display: block; 
    clear: both;
}
div.list li {
    margin-top: 0.3em;
}
a { text-decoration: none; color: #29407C; }
a:hover { text-decoration: underline; color: #D08504; }
</style>
</head>
<body>
<div>
<?php
  function showIfExists($path, $name){
    if(file_exists($path)){
      if(realpath('./')!=realpath($path)){
        $webPath = str_replace('eos/user/t/tomc/www', 'tomc', $path).'/?'.$_SERVER['QUERY_STRING'];
        print "<div><a class=\"bar\" href=\"$webPath\">$name</a></div>";
      } else {
        print "<div><div class=\"bar\">$name</div></div>";
      }
    } else {
      print "<div><div class=\"bar barEmpty\">$name</div></div>";
    }
  }
  function showIfExistsNoQuery($path, $name){
    if(file_exists($path)){
      if(realpath('./')!=realpath($path)){
        $webPath = str_replace('eos/user/t/tomc/www', 'tomc', $path);
        print "<div><a class=\"bar\" href=\"$webPath\">$name</a></div>";
      } else {
        print "<div><div class=\"bar\">$name</div></div>";
      }
    } else {
      print "<div><div class=\"bar barEmpty\">$name</div></div>";
    }
  }

  showIfExists('..', 'parent');
  showIfExistsNoQuery("availableHeavyNeutrinoSamples.txt", 'as .txt file');
  showIfExistsNoQuery("heavyNeutrinoFileList.txt", 'file list');
?>
</div>
<h1><form>filter  <input type="text" name="match" size="30" value="<?php if (isset($_GET['match'])) print htmlspecialchars($_GET['match']);  ?>" /><input type="Submit" value="Go" /></form></h1>
<br style="clear:both" />
<div>
<pre style="font-size:80%">
<?php
  if(file_exists('availableHeavyNeutrinoSamples.txt')){
    $samples = file('availableHeavyNeutrinoSamples.txt');
    $count = 0;
    foreach($samples as $sample){
      $count += 1;
      if ($count > 7 && isset($_GET['match']) && !fnmatch('*'.$_GET['match'].'*', $sample)) continue;
      echo $sample;
    }
  }
?>
</pre>
</div>
</body>
</html>
