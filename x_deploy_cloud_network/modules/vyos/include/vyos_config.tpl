#!/bin/vbash

# THIS CONFIG IS TESTED WITH VYOS 1.3.x, THEY DO SYNTAX CHANGES FROM TIME TO TIME

source /opt/vyatta/etc/functions/script-template
configure
#AWS
set vpn ipsec ike-group AWS lifetime '28800'
set vpn ipsec ike-group AWS proposal 1 dh-group '2'
set vpn ipsec ike-group AWS proposal 1 encryption 'aes128'
set vpn ipsec ike-group AWS proposal 1 hash 'sha1'
set vpn ipsec site-to-site peer ${aws_vgw_ip} authentication mode 'pre-shared-secret'
set vpn ipsec site-to-site peer ${aws_vgw_ip} authentication pre-shared-secret ${aws_tunnel1_psk}
set vpn ipsec site-to-site peer ${aws_vgw_ip} description 'VPC tunnel 1'
set vpn ipsec site-to-site peer ${aws_vgw_ip} ike-group 'AWS'
#anonymize
set vpn ipsec site-to-site peer ${aws_vgw_ip} local-address '192.168.201.10'
set vpn ipsec site-to-site peer ${aws_vgw_ip} vti bind 'vti0'
set vpn ipsec site-to-site peer ${aws_vgw_ip} vti esp-group 'AWS'
set vpn ipsec ipsec-interfaces interface 'eth0'
set vpn ipsec esp-group AWS compression 'disable'
set vpn ipsec esp-group AWS lifetime '3600'
set vpn ipsec esp-group AWS mode 'tunnel'
set vpn ipsec esp-group AWS pfs 'enable'
set vpn ipsec esp-group AWS proposal 1 encryption 'aes128'
set vpn ipsec esp-group AWS proposal 1 hash 'sha1'
set vpn ipsec ike-group AWS dead-peer-detection action 'restart'
set vpn ipsec ike-group AWS dead-peer-detection interval '15'
set vpn ipsec ike-group AWS dead-peer-detection timeout '30'
set interfaces vti vti0 address ${aws_vpn_cgw_local}/30
set interfaces vti vti0 description 'VPC tunnel 1'
set interfaces vti vti0 mtu '1436'
set firewall options interface vti0 adjust-mss 1350
set protocols bgp ${as_number} neighbor ${aws_peering_address} remote-as ${aws_as_number}
set protocols bgp ${as_number} neighbor ${aws_peering_address} timers holdtime '30'
set protocols bgp ${as_number} neighbor ${aws_peering_address} timers keepalive '10'
#Amazon needs to fix their template...
set protocols bgp ${as_number} neighbor ${aws_peering_address} address-family ipv4-unicast soft-reconfiguration 'inbound'
#AZURE
set interfaces vti vti1 address ${azure_peering_address_local}/30
set interfaces vti vti1 description 'AZURE Tunnel'
set interfaces vti vti1 mtu '1400'
set firewall options interface vti1 adjust-mss 1350
set vpn ipsec esp-group AZURE compression 'disable'
set vpn ipsec esp-group AZURE lifetime '3600'
set vpn ipsec esp-group AZURE mode 'tunnel'
set vpn ipsec esp-group AZURE pfs 'dh-group2'
set vpn ipsec esp-group AZURE proposal 1 encryption 'aes256'
set vpn ipsec esp-group AZURE proposal 1 hash 'sha1'
set vpn ipsec ike-group AZURE dead-peer-detection action 'restart'
set vpn ipsec ike-group AZURE dead-peer-detection interval '15'
set vpn ipsec ike-group AZURE dead-peer-detection timeout '30'
set vpn ipsec ike-group AZURE ikev2-reauth 'yes'
set vpn ipsec ike-group AZURE key-exchange 'ikev2'
set vpn ipsec ike-group AZURE lifetime '28800'
set vpn ipsec ike-group AZURE proposal 1 dh-group '2'
set vpn ipsec ike-group AZURE proposal 1 encryption 'aes256'
set vpn ipsec ike-group AZURE proposal 1 hash 'sha1'
#anonymize
set vpn ipsec site-to-site peer ${azure_vgw_ip} authentication id '195.244.235.215'
set vpn ipsec site-to-site peer ${azure_vgw_ip} authentication mode 'pre-shared-secret'
#ToDo: key from azure or generate one
set vpn ipsec site-to-site peer ${azure_vgw_ip} authentication pre-shared-secret ${azure_tunnel1_psk}
set vpn ipsec site-to-site peer ${azure_vgw_ip} authentication remote-id '${azure_vgw_ip}'
#only if NATted or behind FW
set vpn ipsec site-to-site peer ${azure_vgw_ip} connection-type 'initiate'
set vpn ipsec site-to-site peer ${azure_vgw_ip} description 'AZURE PRIMARY TUNNEL'
set vpn ipsec site-to-site peer ${azure_vgw_ip} ike-group 'AZURE'
set vpn ipsec site-to-site peer ${azure_vgw_ip} ikev2-reauth 'inherit'
#anonymize
set vpn ipsec site-to-site peer ${azure_vgw_ip} local-address '192.168.201.10'
set vpn ipsec site-to-site peer ${azure_vgw_ip} vti bind 'vti1'
set vpn ipsec site-to-site peer ${azure_vgw_ip} vti esp-group 'AZURE'
#set vpn ipsec logging log-modes 'all'
#WTF Azure? 1.2?
#set protocols static route ${azure_peering_address}/32 interface vti1
set protocols static interface-route ${azure_peering_address}/32 next-hop-interface vti1
set protocols bgp ${as_number} neighbor ${azure_peering_address} remote-as ${azure_as_number}
set protocols bgp ${as_number} neighbor ${azure_peering_address} address-family ipv4-unicast soft-reconfiguration 'inbound'
set protocols bgp ${as_number} neighbor ${azure_peering_address} timers holdtime '30'
set protocols bgp ${as_number} neighbor ${azure_peering_address} timers keepalive '10'
#really needed if we use APIPA?
set protocols bgp ${as_number} neighbor ${azure_peering_address} disable-connected-check
commit
save
exit
