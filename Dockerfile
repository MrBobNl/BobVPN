# syntax=docker/dockerfile:experimental
FROM ubuntu:22.04

LABEL Maintainer="Bob Jung"
LABEL Titel="BobVPN"
LABEL Sub_title="usermanagement, server, multi-arch and ddns"
LABEL Version="1.0.0"
LABEL Description="Custom implementation of OpenVPN (usermanagement, server, multi-arch and ddns)"

RUN echo "install requirements"
# apt list -a <packagename> for version
RUN apt-get update && apt-get install -y \
    sudo \
    nano \
    dos2unix \
    rsyslog \
    openvpn \
    easy-rsa \
    ca-certificates \
    openssl \
    gcc \
    wget \
    make \
    && rm -rf /var/lib/apt/lists/*

RUN echo "create local user happy"
# -r = create system account, -m --create-home, -d home directory, -G group to root, -u UID, -p password
RUN useradd -rm -d /home/happy -s /bin/bash -g root -G sudo -u 6666 happy -p x
# change password off happy and root (root is a standard user with the ubuntu 20.04 image)
# TODO: change password to whatever you want
RUN echo 'happy:password' | chpasswd
RUN echo 'root:password' | chpasswd

# Set Up and Configure a Certificate Authority (CA)
## login into user happy
RUN echo "log into happy"
USER happy
RUN echo "Set-up and configure CA"
RUN mkdir ~/easy-rsa
RUN ln -s /usr/share/easy-rsa/* ~/easy-rsa/
RUN chmod 700 /home/happy/easy-rsa
WORKDIR /home/happy/easy-rsa
RUN ./easyrsa init-pki
RUN > vars
# TODO: fill in your own information
RUN echo 'set_var EASYRSA_REQ_COUNTRY    "XX"' > vars
RUN echo 'set_var EASYRSA_REQ_PROVINCE   "XXXXXXX"' >> vars
RUN echo 'set_var EASYRSA_REQ_CITY       "XXXX"' >> vars
RUN echo 'set_var EASYRSA_REQ_ORG        "XXX"' >> vars
RUN echo 'set_var EASYRSA_REQ_EMAIL      "XXXXXXXX"' >> vars
RUN echo 'set_var EASYRSA_REQ_OU         "Community"' >> vars
RUN echo 'set_var EASYRSA_ALGO           "ec"' >> vars
RUN echo 'set_var EASYRSA_DIGEST         "sha512"' >> vars
# \n is the command to press enter as answer to the command
RUN echo -ne '\n' | ./easyrsa build-ca nopass
RUN cp ~/easy-rsa/pki/ca.crt /tmp/ca.crt

# put the CA certificate into the server that runs on the root
RUN echo "log into root"
USER root
RUN cp /tmp/ca.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

# Creating and Signing Certificate Request
RUN echo "log into happy"
USER happy
RUN mkdir ~/csr
WORKDIR /home/happy/csr
RUN openssl genrsa -out happy-server.key
# TODO: fill in your own information
RUN openssl req -new -key happy-server.key -out happy-server.req -subj \
    /C=XX/ST=XXXXXXX/L=XXXX/O=XXX/OU=Community/CN=happy-server
RUN openssl req -in happy-server.req -noout -subject
RUN cp happy-server.req /tmp/happy-server.req

# Signing a CSR
RUN echo "Sign CSR"
WORKDIR /home/happy/easy-rsa
RUN ./easyrsa import-req /tmp/happy-server.req happy-server
RUN yes yes | ./easyrsa sign-req server happy-server
RUN cp pki/issued/happy-server.crt /tmp
RUN cp pki/ca.crt /tmp

# Set Up and Configure an OpenVPN Server
RUN echo "Set-up openVPN server"
RUN echo "log into root"
USER root
RUN sudo chown happy /home/happy/easy-rsa
RUN chmod 700 /home/happy/easy-rsa
# Create PKI
RUN echo "create PKI"
RUN mkdir ~/easy-rsa
RUN ln -s /usr/share/easy-rsa/* ~/easy-rsa/
WORKDIR /root/easy-rsa
RUN > vars
RUN echo 'set_var EASYRSA_ALGO "ec"' > vars
RUN echo 'set_var EASYRSA_DIGEST "sha512"' >> vars
RUN ./easyrsa init-pki
RUN echo "log into happy"
USER happy
WORKDIR /home/happy/easy-rsa
RUN echo '\n' | ./easyrsa gen-req server nopass
RUN echo "log into root"
USER root
RUN sudo cp /home/happy/easy-rsa/pki/private/server.key /etc/openvpn/server/
RUN echo "log into happy"
USER happy
WORKDIR /home/happy/easy-rsa
RUN yes yes | ./easyrsa sign-req server server
RUN cp pki/issued/server.crt /tmp
RUN cp pki/ca.crt /tmp
RUN echo "log into root"
USER root
RUN cp /tmp/server.crt /etc/openvpn/server
RUN cp /tmp/ca.crt /etc/openvpn/server
# Cryptographic material
WORKDIR /root/easy-rsa
RUN openvpn --genkey --secret ta.key
RUN cp ta.key /etc/openvpn/server

# Base for generating client CA and key pairs
## Still needs some fixes with the client.sh bash script for some reason...
RUN echo "log into root"
USER root
WORKDIR /
RUN mkdir /root/client-configs
ADD /client-configs/client.sh /root/client-configs/base.conf
ADD /client-configs/client.sh /root/client-configs/client.sh
ADD /client-configs/make_config.sh /root/client-configs/make_config.sh
RUN chmod -R 755 /root/client-configs
RUN chmod -R 755 /root/client-configs/client.sh
RUN chmod -R 755 /root/client-configs/make_config.sh
WORKDIR /root/client-configs
RUN mkdir files
RUN mkdir keys

# Copy pasta server settings in docker
COPY server.conf /etc/openvpn/server/server.conf
WORKDIR /etc/openvpn/server
RUN cp ca.crt ..
RUN cp server.conf ..
RUN cp server.crt ..
RUN cp server.key ..
RUN cp ta.key ..
WORKDIR /etc/openvpn/
RUN mkdir ccd
# add readme
RUN echo 'Be sure to make the client that u want to manage has the exact name ass the file name' > /etc/openvpn/ccd/readme.md
# sample static ip
RUN echo 'ifconfig-push 10.7.0.5 10.7.0.6' > /etc/openvpn/ccd/sample_static_ip
# sample public ip change
RUN echo 'ifconfig-push 10.7.0.9 10.7.0.10' > /etc/openvpn/ccd/sample_public_ip
RUN echo 'redirect-gateway autolocal def1 bypass-dhcp' >> /etc/openvpn/ccd/sample_public_ip
RUN echo 'dhcp-option DNS 208.67.220.222' >> /etc/openvpn/ccd/sample_public_ip
RUN echo 'dhcp-option DNS 208.67.220.220' >> /etc/openvpn/ccd/sample_public_ip
RUN echo 'block-outside-dns' >> /etc/openvpn/ccd/sample_public_ip

# Adjust network configurations
RUN echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf

# DDNS installation for noip
RUN echo "log into root"
USER root
WORKDIR /usr/local/src/
RUN wget http://www.noip.com/client/linux/noip-duc-linux.tar.gz
RUN tar xf noip-duc-linux.tar.gz
WORKDIR /usr/local/src/noip-2.1.9-1/
RUN make
# https://www.noip.com/support/knowledgebase/installing-the-linux-dynamic-update-client-on-ubuntu/
# https://my.noip.com/dynamic-dns

# Run configuration.sh shell script to do some configuration and start the openvpn service
WORKDIR /
ADD configuration.sh configuration.sh
#RUN apt-get install -y dos2unix && dos2unix /configuration.sh && chmod 755 configuration.sh
RUN dos2unix /configuration.sh && chmod 755 configuration.sh
ENTRYPOINT ["/configuration.sh"]

# Make this te directory where you start when entering the docker container
WORKDIR /root/client-configs