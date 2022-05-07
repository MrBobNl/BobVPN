# BobVPN
Custom implementation of OpenVPN (usermanagement, server, multi-arch and ddns)

Work in proces! It works but stil needs adjustment hardcoded!
If you are using Visual Studio Code, install the extension: Todo Tree. you will get a tree on your left bar with what you need to fill in before the build.

# Introduction
Your looking for an managed OpenVPN with an usermanagement in there that works multi-arch? Stop looking! :D

This project is to build an image for your container registry. Everything is based on ubuntu 22.04 LTS, at the moment it is build for linux/amd64,linux/arm64,linux/riscv64,linux/ppc64le,linux/s390x,linux/arm/v7. In other words, for almost every system like 32-bit (arm/v7) and 64-bit (arm64) on raspberry and windows computers (amd64).

## Getting Started
### prerequiste
- [docker](docker.com) (Windows wsl, Ubuntu, Debain)
- [dockerhub](hub.docker.com)
- [ ] Tested on
```
- Windows 10 wsl(2)
- Windows 11 wsl(2)
- Ubuntu(18.04,20.04,22.04)
```
### Installation process
#### Making the image
- [ ] Configure docker for the multiarch build
```
export DOCKER_CLI_EXPERIMENTAL=enabled
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx create --use
```
- [ ] Building the image
```
git clone git@github.com:MrBobNl/BobVPN.git
change all the # TODO using the tree or just ctrl-f for the text TODO in all the files
docker login -u username -p password
# note this can take a while, remove platforms you don't need if you don't want them
docker buildx build -t username/container:version --platform linux/amd64,linux/arm64,linux/riscv64,linux/ppc64le,linux/s390x,linux/arm/v7 --push .
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
- [ ] Running the docker on the edge
1. Running your build image on your device
```
# TODO
docker login -u username -p password
docker run -it -d --restart=unless-stopped --cap-add=NET_ADMIN --privileged --network=host --hostname **** --name **** username/container:version
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
- [ ] You can see in the logs of the docker container what is happening, if there is nothing it is probraly the port forwarding
```
Portforwarding
- Ports: The external port is the same as in the client. The internal port needs to be the same as the docker container.
- Protocol: UDP (not tcp)
```
- [ ] The TLS is not going alright, the config is copy pasted correctly.
Example the client on a iphone can't have any empty lines

## sources
- [digitalocean](www.digitalocean.com)
- [noip](noip.com)
- [openvpn](openvpn.net)
- [stackoverflow](https://stackoverflow.com/questions/59451531/how-to-create-tun-interface-inside-docker-container-image)