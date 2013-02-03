<?php



		 

$args = array(
  'jsonrpc'  => "2.0",
  'method' =>  "fs.list",
  'id'  => 0.1816119037070476,
  'params'   => 
	array(
	   '/Disque dur/mirror/',
	   array("with_attr" => true)
   )
);

$json = json_encode($args) . "\n";
$json = str_replace('\/', '/', $json);
echo $json . "\n";

# {"method":"fs.list","jsonrpc":"2.0","params":["/Disque dur/mirror/",{"with_attr":"true"}]}
# {"jsonrpc":"2.0","method":"fs.list","id":0.1816119037070476,"params":["/Disque dur/mirror/",{"with_attr":true}]}
# {"jsonrpc":"2.0","method":"fs.list","id":0.18161190370705,  "params":["/Disque dur/mirror/",{"with_attr":"true"}]}

?>
