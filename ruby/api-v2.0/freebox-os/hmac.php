<?php

error_reporting(E_ALL);

$token = 'xLNf2M9Odj85GKAdNoLlaRa3FDuUtmj18QoYPN2l9uK60ikP7kxFWEBjDZ4Ue3jy';
$password = '6cf9e85ce94b6b7f03919abbea647d7af16f2a13';
$challenge = 'jVjwXSpEOld0UxcOhHDVx4znK20JgUNz';
$key = '';

echo hash_hmac("sha1", $token, $challenge) . "\n";
echo hash_hmac("sha1", $challenge, $token) . "\n";

?>
