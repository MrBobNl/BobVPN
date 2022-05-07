#!/bin/bash
echo "root"
cd ~/easy-rsa
echo "Fill in the desired client name: "
read client
echo "You filled in: $client"
./easyrsa gen-req $client nopass
cp pki/private/$client.key ~/client-configs/keys/

cp pki/reqs/$client.req /tmp

echo "happy"
cd /home/happy/easy-rsa
./easyrsa import-req /tmp/$client.req $client
./easyrsa sign-req client $client

cp pki/issued/$client.crt /tmp

echo "root"
cp /tmp/$client.crt ~/client-configs/keys/
cp ~/easy-rsa/ta.key ~/client-configs/keys/
cp /etc/openvpn/ca.crt ~/client-configs/keys/

cd ~/client-configs

./make_config.sh $client