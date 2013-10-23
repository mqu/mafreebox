#! /bin/bash
. ./resty.sh

# remote site 
# resty 'http://mafreebox.freebox.fr/'
resty 'mafreebox.freebox.fr:80'

result=$( mktemp )
GET /api/v1/login >& $result
echo -n "## login (json) : "
cat $result

# GET /api/v1/login | python -mjson.tool
# exit

result=`grep "challenge" $result | cut -f 5 -d ':' | cut -f 1 -d ','|sed "s/\"//g"| sed "s/\r//g" | sed "s/\n//g" | sed -e 's#\\/#/#g'` 
echo -n "## challenge : "
echo $result

echo -n "## password : "
result=`echo -n $result | openssl dgst -sha1 -hmac "89vtuOaDxJ/TDeBDPgWSk9083SbQgEMnHdIGoHg2qK2tpWcLuiRofIjuxZSG8yJn" | sed -e 's#(stdin)= ##'`
echo $result

POST /api/v1/login/session '{"app_id": "89vtuOaDxJ/TDeBDPgWSk9083SbQgEMnHdIGoHg2qK2tpWcLuiRofIjuxZSG8yJn","password": "'$result'"}' -v
