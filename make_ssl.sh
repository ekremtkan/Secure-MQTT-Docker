#!/bin/bash

wd="`dirname $0`"
if [ ! -z "$wd" ]; then
    if [ $wd == "." ];then wd=`pwd`;fi  
fi

certDir="${wd}/certs";

rm -rf ${certDir} ;mkdir -p ${certDir}

cd ${certDir}

#Server IP - Port bilgileri
#~ IP="192.168.1.22"
IP="192.168.1.10"
PORT="8883"

SUBJECT_CA="/C=TR/ST=Istanbul/L=Istanbul/O=IKOM_BILISIM/OU=CA/CN=$IP"
SUBJECT_SERVER="/C=TR/ST=Istanbul/L=Istanbul/O=IKOM_BILISIM/OU=Server/CN=$IP"
SUBJECT_CLIENT="/C=TR/ST=Istanbul/L=Istanbul/O=IKOM_BILISIM/OU=Client/CN=$IP"

function generate_CA () {
   echo "$SUBJECT_CA"
   openssl req -x509 -nodes -sha256 -newkey rsa:2048 -subj "$SUBJECT_CA"  -days 365 -keyout ca.key -out ca.crt
}

function generate_server () {
   echo "$SUBJECT_SERVER"
   openssl req -nodes -sha256 -new -subj "$SUBJECT_SERVER" -keyout server.key -out server.csr
   openssl x509 -req -sha256 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365
}

function generate_client () {
   echo "$SUBJECT_CLIENT"
   openssl req -new -nodes -sha256 -subj "$SUBJECT_CLIENT" -out client.csr -keyout client.key 
   openssl x509 -req -sha256 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365
}

function clean () {
   echo "$SUBJECT_CLIENT"
    rm client.csr client.key client.crt 
    rm server.csr server.key server.crt 
    rm ca.srl ca.key ca.crt 
}


echo "port ${PORT}

cafile ${wd}/certs/ca.crt
certfile ${wd}/certs/server.crt
keyfile ${wd}/certs/server.key

require_certificate true
use_identity_as_username true
" > mosquitto.conf

clean
generate_CA
generate_server
generate_client

cd ${wd}


echo "Use Examples
#Server

mosquitto -c ${certDir}/mosquitto.conf -v

#Subcriber

mosquitto_sub -h ${IP} -p ${PORT}  --cafile ${certDir}/ca.crt --cert ${certDir}/client.crt --key ${certDir}/client.key -t temperature

#Publisher

mosquitto_pub  -h ${IP} -p ${PORT} --cafile ${certDir}/ca.crt --cert ${certDir}/client.crt --key ${certDir}/client.key -t temperature -m elma

"
