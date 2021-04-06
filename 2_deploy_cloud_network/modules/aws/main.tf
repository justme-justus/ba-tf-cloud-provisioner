terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = "3.35.0"
		}
	}
}

provider "aws" {
}

resource "aws_vpc" "aws_vpc" {
	cidr_block = "${var.subnet}/${var.subnet_mask}"
	instance_tenancy = "default"
}

resource "aws_vpn_gateway" "aws_vpn_gateway" {
	vpc_id = aws_vpc.aws_vpc.id
	amazon_side_asn = var.as_number
}

resource "aws_customer_gateway" "azure_gateway" {
	bgp_asn = var.azure_as_number
	//external IP address of VPN concentrator
	ip_address = var.azure_vgw_ip
	type = "ipsec.1"
}

resource "aws_customer_gateway" "vyos_gateway" {
	bgp_asn = var.vyos_as_number
	//external IP address of VPN concentrator
	ip_address = var.vyos_vgw_ip
	type = "ipsec.1"
}

resource "aws_vpn_connection" "azure_vpn_connection" {
	vpn_gateway_id = aws_vpn_gateway.aws_vpn_gateway.id
	customer_gateway_id = aws_customer_gateway.azure_gateway.id
	type = "ipsec.1"
	tunnel1_inside_cidr = var.azure_peering_subnet
}

resource "aws_vpn_connection" "vyos_vpn_connection" {
	vpn_gateway_id = aws_vpn_gateway.aws_vpn_gateway.id
	customer_gateway_id = aws_customer_gateway.vyos_gateway.id
	type = "ipsec.1"
}

resource "aws_vpn_gateway_route_propagation" "aws_vpn_gateway_route_propagation" {
	vpn_gateway_id = aws_vpn_gateway.aws_vpn_gateway.id
	route_table_id = aws_vpc.aws_vpc.main_route_table_id
}

resource "aws_subnet" "aws_subnet" {
	vpc_id = aws_vpc.aws_vpc.id
	cidr_block = "${var.subnet}/${var.subnet_mask}"
}

output "azure_vpn_outside_ip" {
	value = aws_vpn_connection.azure_vpn_connection.tunnel1_address
}

output "azure_vpn_tunnel1_psk" {
	value = aws_vpn_connection.azure_vpn_connection.tunnel1_preshared_key
}

output "vyos_vpn_outside_ip" {
	value = aws_vpn_connection.vyos_vpn_connection.tunnel1_address
}

//vyos _own_ internal IP
output "vyos_vpn_cgw" {
	value = aws_vpn_connection.vyos_vpn_connection.tunnel1_cgw_inside_address
}

//aws site internal IP
output "vyos_vpn_vgw" {
	value = aws_vpn_connection.vyos_vpn_connection.tunnel1_vgw_inside_address
}

output "vyos_vpn_tunnel1_psk" {
	value = aws_vpn_connection.vyos_vpn_connection.tunnel1_preshared_key
}
