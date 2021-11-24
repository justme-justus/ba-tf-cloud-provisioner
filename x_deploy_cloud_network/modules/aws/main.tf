terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = "3.35.0"
		}
	}
}

resource "aws_vpc" "aws_vpc" {
	cidr_block = "${var.subnet}/${var.subnet_mask}"
	instance_tenancy = "default"
}

resource "aws_subnet" "aws_subnet" {
	vpc_id = aws_vpc.aws_vpc.id
	cidr_block = "${var.subnet}/${var.subnet_mask}"
}

#resource "aws_vpn_gateway" "aws_vpn_gateway" {
#	vpc_id = aws_vpc.aws_vpc.id
#	amazon_side_asn = var.as_number
#}

//VGW replaced by TGW
resource "aws_ec2_transit_gateway" "aws_ec2_transit_gateway" {
        description = "TGW_TF"
        amazon_side_asn = var.as_number
	default_route_table_propagation = "enable"
	dns_support = "enable"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "aws_ec2_transit_gateway_vpc_attachment" {
        transit_gateway_id = aws_ec2_transit_gateway.aws_ec2_transit_gateway.id
        subnet_ids = [ aws_subnet.aws_subnet.id ]
        vpc_id = aws_vpc.aws_vpc.id
}

//route 10.0.0.0/8 statically to TG
resource "aws_route" "aws_route" {
	route_table_id = aws_vpc.aws_vpc.main_route_table_id
	destination_cidr_block = "10.0.0.0/8"
	transit_gateway_id = aws_ec2_transit_gateway.aws_ec2_transit_gateway.id
}

resource "aws_route" "aws_route_2" {
	route_table_id = aws_vpc.aws_vpc.main_route_table_id
	destination_cidr_block = "192.168.0.0/16"
	transit_gateway_id = aws_ec2_transit_gateway.aws_ec2_transit_gateway.id
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
	#vpn_gateway_id = aws_vpn_gateway.aws_vpn_gateway.id
	transit_gateway_id = aws_ec2_transit_gateway.aws_ec2_transit_gateway.id
	customer_gateway_id = aws_customer_gateway.azure_gateway.id
	type = "ipsec.1"
	tunnel1_inside_cidr = var.azure_peering_subnet
}

resource "aws_vpn_connection" "vyos_vpn_connection" {
	#vpn_gateway_id = aws_vpn_gateway.aws_vpn_gateway.id
	transit_gateway_id = aws_ec2_transit_gateway.aws_ec2_transit_gateway.id
	customer_gateway_id = aws_customer_gateway.vyos_gateway.id
	type = "ipsec.1"
}

#resource "aws_vpn_gateway_route_propagation" "aws_vpn_gateway_route_propagation" {
#	vpn_gateway_id = aws_vpn_gateway.aws_vpn_gateway.id
#	route_table_id = aws_vpc.aws_vpc.main_route_table_id
#}

output "azure_vpn_outside_ip" {
	value = aws_vpn_connection.azure_vpn_connection.tunnel1_address
}

output "azure_vpn_tunnel1_psk" {
	value = aws_vpn_connection.azure_vpn_connection.tunnel1_preshared_key
	sensitive = true
}

output "vyos_vpn_outside_ip" {
	value = aws_vpn_connection.vyos_vpn_connection.tunnel1_address
}

//passthrough to remote states
output "tg_id" {
	value = aws_ec2_transit_gateway.aws_ec2_transit_gateway.id
}

output "tg_default_rt_id" {
	value = aws_ec2_transit_gateway.aws_ec2_transit_gateway.association_default_route_table_id
}

output "vpc_main_rt" {
	value = aws_vpc.aws_vpc.main_route_table_id
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
	sensitive = true
}

# passthrough to root module for remote state import
output "vpc_id" {
	value = aws_vpc.aws_vpc.id
}

output "subnet_id" {
	value = aws_subnet.aws_subnet.id
}
