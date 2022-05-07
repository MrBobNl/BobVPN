#!/bin/bash

echo "$(whoami)"
# log to syslog
rsyslogd
# Starting openVPN as service
## Use service instead off systemctl
sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn
# Make tun to use
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
# start openvpn service
service openvpn start

# start cron to use later if wanted
service cron start

# otherwise it wil stay in the script forever
sleep infinity