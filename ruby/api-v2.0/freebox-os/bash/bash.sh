#!/bin/bash

challenge='h8P7jCdXp\/7NNAkoqZOXu+VC7rK5t1kc'
echo $challenge

challenge="h8P7jCdXp\/7NNAkoqZOXu+VC7rK5t1kc"
echo $challenge

challenge=$challenge
echo $challenge

echo $challenge | cat

passwd=`echo -n $result | openssl dgst -sha1 -hmac "<app_token>" | sed -e 's#(stdin)= ##'`
echo $passwd

