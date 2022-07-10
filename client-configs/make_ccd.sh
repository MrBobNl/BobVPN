# not tested yet!
echo "Fill in the desired client name: "
read client
echo "You filled in: $client"
echo "Do you want to give the client a static IP-Address? yes or no"
read decision_one
echo "Do you desire that the public ip changes with the connection? yes or no"
read decision_two
if ["$decision_one" = "yes"]; then
    echo "Before you choose, take in account that a /30 subnets is used!"
    echo "example choose -> [5, 6] [9, 10] [13, 14] etc"
    echo "What number do you want to give the client?"
    read number_one
    read number_two
    echo "You filled in: $number_one and $number_two"
    echo "ifconfig 10.5.0.$number_one 10.5.0.$number_two" > /etc/openvpn/ccd/$client
    if ["$decision_two" = "yes"]; then
        echo "redirect-gateway autolocal def1 bypass-dhcp" >> /etc/openvpn/ccd/$client
        echo "dhcp-option DNS 1.1.1.1" >> /etc/openvpn/ccd/$client
        echo "dhcp-option DNS 1.0.0.1" >> /etc/openvpn/ccd/$client
        echo "redirect-gateway autolocal def1 bypass-dhcp" >> /etc/openvpn/ccd/$client
    else
        echo "You did not choose for public ip"
    fi
else
    echo "You did not choose for a static IP-Address"
fi