# BobVPN
Custom implementation of OpenVPN (usermanagement, server, multi-arch and ddns)

I use it myself now regularly. Last usage is to add an Robustel R2011 to my container to be able to talk to the network the is behind it. For proof of conceps in hard to reach location it is perfect! Plug it in, everything has an network and internet + secure connection over the vpn of the container :D But still not in the final state i would like, so if you use it, please let me know what i can improve or if you have suggestion ofcourse ;-)
Left some TODO's in there, if you are using Visual Studio Code, install the extension: Todo Tree. You will get a tree on your left bar with what you need to fill in before the build.

# Introduction
Your looking for an managed OpenVPN with an usermanagement in there that works multi-arch? Stop looking! :D

This project is to build an image for your container registry. Everything is based on ubuntu 22.04 LTS, at the moment it is build for linux/amd64,linux/arm64,linux/riscv64,linux/ppc64le,linux/s390x,linux/arm/v7. In other words, for almost every system like 32-bit (arm/v7) and 64-bit (arm64) on raspberry and windows computers (amd64).

# Table of Contents

1. [Getting Started](#Getting-Started)
2. [Usage](#Usage)
2. [Troubleshooting](#troubleshooting)
3. [sources](#sources)

## Getting Started
### prerequiste
- [docker](docker.com) (Windows wsl, Ubuntu, Debain)
- [dockerhub](hub.docker.com)

### regularly on (tested)
```
- Ubuntu 18.04 & 20.04
- Debian Stretch & buster
- Probraly works for more but not used yet, please let me know if you do :D
```

### Experienced user
If you have worked with OpenVPN or/and with networks regularly before. Then i would just jump into making the image, configure your Modem and/or router yourself with the desired firewall yourself and you will probraly be go to go for an solid 95% already. Just jump into the last part to created a client in the docker in the client-configs folder :D Still to steep of an step? there is an step by step down under here :D

### Step-by-step installation process
If you have no rights, just type sudo in front of every command ;-) or loggin with sudo -i as root.
#### Making the image
- [] Configure docker for the multiarch build
```
export DOCKER_CLI_EXPERIMENTAL=enabled
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx create --use
```
- [] Building the image
```
git clone git@github.com:MrBobNl/BobVPN.git
change all the # TODO using the tree or just ctrl-f for the text TODO in all the files
docker login -u username -p password
# note this can take a while, remove platforms you don't need if you don't want them
docker buildx build \
--build-arg password=example_password \
--build-arg country=NL \
--build-arg province=NoordBrabant \
--build-arg city=BergenOpZoom \
--build-arg email=example@vpn.com \
--build-arg public_ip=example.ddns.net \
--build-arg internal_port=1194 \
--build-arg external_port=1194 \
-t username/container:version --platform linux/amd64,linux/arm64,linux/riscv64,linux/ppc64le,linux/s390x,linux/arm/v7 --push .

Note* if you run into: authorization failed. Big chance you did not login yet into your docker hub
```
#### Configure network
1. Modem 
```
# TODO
Give your device a static IP-Address and route the port you choose to the device.
example: 
Service Name	        External Port	Internal Port	Internal IP Address	    Protocol	Source IP	Edit	Delete
Open VPN Server Docker	****	        ****            *.*.*.*         	    UDP			
```
2. Modem + router
```
# TODO
Give your router a static IP-Address and route the port you choose to the router. The second step is practically the same to the device.
example: 
Service Name	        External Port	Internal Port	Internal IP Address	    Protocol	Source IP	Edit	Delete
Modem to router VPN 	****	        ****            *.*.*.*         	    UDP			
Service Name	        External Port	Internal Port	Internal IP Address	    Protocol	Source IP	Edit	Delete
Open VPN Server Docker	****	        ****            *.*.*.*         	    UDP		
```
#### Configuration device
1. login as root
```
sudo -i
```
2. Allow ip_forward
```
nano /etc/sysctl.conf
"""
allow net.ipv4.ip_forward = 1
"""
```
3. Allow the firewall to be default accept forwards
Note* firewall is optional, but use it! if you don't know what a firewall does. Search engines are your friends!
```
nano /etc/default/ufw
"""
DEFAULT_FORWARD_POLICY="ACCEPT"
"""
```
4. Allow traffic from the vpn to the right interface with routing in your firewall
```
# TODO
ip a
-> search for the interface you want to use (it needs to be the default one) like eth0 or eno1 etc.
nano /etc/ufw/before.rules
copy pasta this after:
# rules.before
#
# Rules that should be run before the ufw command line added rules. Custom
# rules should be added to one of these chains:
#   ufw-before-input
#   ufw-before-output
#   ufw-before-forward
"""
# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0 (change to the interface you found! and if you change the domain network)
-A POSTROUTING -s 10.5.0.0/24 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES
"""
```
5. Configure your firewall to allow udp communication over the chosen port
```
# TODO
ufw allow ****/udp
ufw allow OpenSSH
ufw disable
ufw enable
```
6. Reroute traffic to the tunnel. (mandatory if you want internet with the change off public ip)
```
# TODO
iptables -t nat -A POSTROUTING -s 10.5.0.0/24 -o eth1 -j MASQUERADE
# note* sometimes it does not save it after reboot. If this happens do the following
# do the configurations and then install (it saves it at /etc/iptables/rules.v4 and /etc/iptables/rules.v6)
apt install iptables-persistent
```
7. Check if there is more then one connection, make sure you route to your default gateway
```
# TODO
route change -net default gw *.*.*.* netmask 0.0.0.0 dev eth0 metric 1 static
```
- [] Running the docker on the edge
1. Running your build image on your device
```
# TODO
docker login -u username -p password
docker run -it -d --restart=unless-stopped --cap-add=NET_ADMIN --privileged --network=host --hostname bobvpn --name bobvpn username/container:version
```
2. Making an client
```
docker exec -it **$name** bash
# at the moment for some reason the bash script does not work properly from the build if you remove it and make a new one copy pasta the file in there it works fine. If you know what it is let me know :D
bash client.sh
there should be a client in the location files copy it into your client, it should work :D
```
3. DDNS if your public ip switches.
```
Make an user on [noip](noip.com)
create a hostname
```
4. Configure DDNS on the edge
```
cd /usr/local/src/noip-2.1.9-1
make install
Start te ddns program (autostart will come later)
# if the configuration goes wrong for a retry -> /usr/local/bin/noip2 -C
/usr/local/bin/noip2    # Starts the program
```
### Common mistakes to check
- [] You can see in the logs of the docker container what is happening, if there is nothing it is probraly the port forwarding
```
Portforwarding
- Ports: The external port is the same as in the client. The internal port needs to be the same as the docker container.
- Protocol: UDP (not tcp)
```
- [] The TLS is not going alright, the config is copy pasted correctly.
Example the client on a iphone can't have any empty lines

## Usage
When you have started up the container and everything is working it is time to start making clients and troubleshooting when necessary.
1. Making users usually i just use the bash client.sh and give them the rights i want with the ccd
2. Installing client on ubuntu with autoconnect
sudo apt-get install openvpn
*test config with -> (sudo) openvpn --config client.ovpn
nano /etc/openvpn/client.conf 'insert config'
sudo reboot
check with ip a
3. Installing client on windows with autoconnect
Just use the OpenVPN GUI for windows
[OpenVPN-GUI-for-windows](https://openvpn.net/community-downloads/)
2. If you wish to get to a network behind a client simply uncomment the iroute part and insert your own network that you want to reach. and add the route in the server the same way! :D
3. If you want to see the lag just use something like tail -f or watch or to look into the logs. (/var/log/openvpn/openvpn.log) Also possible to look at the status, but it is much slower in refresh rate!

## Troubleshooting
1. Most of the times it is a typo or a small configuration that gone wrong. It can be as simple as that in the modem only TCP is let through instead of UDP. So first step is take a breather and read all the steps again.
2. Next step would be go into the logs and google the isseu at hand. Try turning on/off the firewall for example to look what the problem can be.
3. As last resort you can contact me, i will do my best to be helpfull :D

## sources
- [digitalocean](https://www.digitalocean.com/)
- [noip](https://www.noip.com/)
- [openvpn](https://openvpn.net/)
- [stackoverflow](https://stackoverflow.com/questions/59451531/how-to-create-tun-interface-inside-docker-container-image)