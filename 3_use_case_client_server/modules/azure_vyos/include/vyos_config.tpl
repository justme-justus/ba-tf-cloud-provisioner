#!/bin/vbash

# THIS CONFIG IS TESTED WITH VYOS 1.3.x, THEY DO SYNTAX CHANGES FROM TIME TO TIME

#generate DH parameters
openssl dhparam -out /config/auth/dh2048.pem 2048

source /opt/vyatta/etc/functions/script-template
configure

########### actual config ###########
#accelerate SSH login
set service ssh disable-host-validation
set system host-name vyos-azure-ovpn-gw
#add SSH key jum@netuse.de
#better: get key from file not plain as string?
set system login user vyos authentication public-keys jum@netuse.de key AAAAB3NzaC1yc2EAAAADAQABAAABAQDU45kZAdvcqQfd1vkw2/3EmzIPvgLYYThz1ep5rBiBFb71kbvI6Us7ds4aNz8+7P+AHzy7LUYrJfnc8APKQrFM14bcGzXM1B3M3tNfxGlSFVGyarcua/X45qIKzAD9mgSj7QYDKc0s2/DD6YQ6BialRQoZjbCKmNWyvgn4qi/ynzkP8cWP9bfNk7UhjiQcaITHYlmVfSEDBXDWer8NALMN21XF9ujH49lUuhIYIO0zLsH5lyL+mrlo2oLzQx6kIHVR/1XyqxEdTh8LcxDq5VWTvMP8nvRsrptG+r97kyAbcB2+pusSAMfYuO7CX4x/RVmamtoCCWfpV0rTfpFmPNAt
set system login user vyos authentication public-keys jum@netuse.de type ssh-rsa
set system name-server 8.8.8.8
#OpenVPN
set interfaces openvpn vtun0 encryption 'aes256'
set interfaces openvpn vtun0 local-port '61231'
set interfaces openvpn vtun0 mode 'server'
set interfaces openvpn vtun0 persistent-tunnel
set interfaces openvpn vtun0 protocol 'udp'
#MSS least common denominator == 1350
#https://docs.microsoft.com/de-de/azure/virtual-network/virtual-network-tcpip-performance-tuning
#https://docs.aws.amazon.com/vpn/latest/s2svpn/your-cgw.html
set interfaces openvpn vtun0 openvpn-option "--mssfix 1350"
set interfaces openvpn vtun0 server domain-name 'intern.ba.mungard.de'
set interfaces openvpn vtun0 server name-server '192.168.201.1'
#"dynamic" routes?
set interfaces openvpn vtun0 server push-route '10.32.0.0/16'
set interfaces openvpn vtun0 server push-route '10.33.0.0/16'
set interfaces openvpn vtun0 server push-route '192.168.201.0/24'
set interfaces openvpn vtun0 server subnet ${azure_vpn_clients_subnet}/${azure_vpn_clients_subnet_mask}
set interfaces openvpn vtun0 tls ca-cert-file '/config/auth/BA_CA_2021.crt'
set interfaces openvpn vtun0 tls cert-file '/config/auth/vpn-server-azure.ba.mungard.de.crt'
set interfaces openvpn vtun0 tls dh-file '/config/auth/dh2048.pem'
set interfaces openvpn vtun0 tls key-file '/config/auth/vpn-server-azure.ba.mungard.de.key'
########### actual config ###########

commit
save
exit
