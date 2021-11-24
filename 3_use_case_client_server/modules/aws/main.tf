terraform {
        required_providers {
                aws = {
                        source = "hashicorp/aws"
                        version = "~> 3.35.0"
                }
        }
}

resource "aws_vpc" "aws_vpc" {
        cidr_block = "${var.vpn_client_transfer_subnet}/${var.vpn_client_transfer_subnet_mask}"
        instance_tenancy = "default"
}

resource "aws_subnet" "aws_subnet" {
        vpc_id = aws_vpc.aws_vpc.id
        cidr_block = "${var.vpn_client_transfer_subnet}/${var.vpn_client_transfer_subnet_mask}"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "aws_ec2_transit_gateway_vpc_attachment" {
        transit_gateway_id = var.transit_gateway_id
        subnet_ids = [ aws_subnet.aws_subnet.id ]
        vpc_id = aws_vpc.aws_vpc.id
}

resource "aws_internet_gateway" "aws_internet_gateway" {
	vpc_id = aws_vpc.aws_vpc.id
}

resource "aws_route" "aws_route_client_vpc_to_tg" {
	//ToDo: 192.168./16? Prefix list? Dynamic TF var?
	//route 10.0.0.0/8 statically to TG, unfortunately we still need 0.0.0.0/0 for internet
        destination_cidr_block = "10.0.0.0/8"
        route_table_id = aws_vpc.aws_vpc.main_route_table_id
        transit_gateway_id = var.transit_gateway_id
}

resource "aws_route" "aws_route_client_vpc_to_tg_2" {
	//ToDo: 192.168./16? Prefix list? Dynamic TF var?
	//route 10.0.0.0/8 statically to TG, unfortunately we still need 0.0.0.0/0 for internet
        destination_cidr_block = "192.168.0.0/16"
        route_table_id = aws_vpc.aws_vpc.main_route_table_id
        transit_gateway_id = var.transit_gateway_id
}

resource "aws_route" "aws_route_client_vpc_to_internet" {
        destination_cidr_block = "0.0.0.0/0"
        route_table_id = aws_vpc.aws_vpc.main_route_table_id
	gateway_id = aws_internet_gateway.aws_internet_gateway.id
}


//add route to VPN client network to "main vpc"
resource "aws_route" "aws_route_main_vpc" {
        destination_cidr_block = "${var.vpn_clients_subnet}/${var.vpn_clients_subnet_mask}"
        route_table_id = var.vpc_main_rt_id
        transit_gateway_id = var.transit_gateway_id
}

//add route to VPN client network to TG
resource "aws_ec2_transit_gateway_route" "aws_ec2_transit_gateway_route" {
        destination_cidr_block = "${var.vpn_clients_subnet}/${var.vpn_clients_subnet_mask}"
        transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.aws_ec2_transit_gateway_vpc_attachment.id
        transit_gateway_route_table_id = var.tg_default_rt_id
}

//add static route to VPN client network to "client vpc"
resource "aws_route" "aws_route_client_vpc_to_clients" {
        destination_cidr_block = "${var.vpn_clients_subnet}/${var.vpn_clients_subnet_mask}"
        route_table_id = aws_vpc.aws_vpc.main_route_table_id
        network_interface_id = aws_instance.aws_instance.primary_network_interface_id
}

resource "aws_security_group" "aws_security_group" {
	name        = "allow_rfc_and_openvpn_inbound_and_any_outbound"
	description = "Allow RFC addresses inbound traffic, allow any outbound"
	vpc_id      = aws_vpc.aws_vpc.id
	
	//https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
	ingress {
		description      = "10./8 and 192.168./16"
		from_port        = 0
		to_port          = 0
		protocol         = "-1"
		cidr_blocks      = [ "10.0.0.0/8", "192.168.0.0/16" ]
	}
	ingress {
		description      = "OpenVPN any inbound"
		from_port        = 61231
		to_port          = 61231
		protocol         = "udp"
		cidr_blocks      = [ "0.0.0.0/0" ]
	}
	egress {
		from_port        = 0
		to_port          = 0
		protocol         = "-1"
		cidr_blocks      = ["0.0.0.0/0"]
	}
}

// find VyOS from AWS marketplace
#data "aws_ami" "aws_ami" {
#        most_recent = true
#        name_regex = "VyOS\\s\\(HVM\\)\\s1\\.2\\.7"
#        owners = [ "aws-marketplace" ]
#}

resource "aws_instance" "aws_instance" {
        #ami = data.aws_ami.aws_ami.id
	//Frankfurt: VyOS 1.2.7
	ami = "ami-08c37a0c3a8a4106d"
        instance_type = "t3a.medium"
        source_dest_check = false
        subnet_id = aws_subnet.aws_subnet.id
        key_name = "key_automation"
	associate_public_ip_address = true
	vpc_security_group_ids = [ aws_security_group.aws_security_group.id ]
}

output "vyos_internal_ip" {
	value = aws_instance.aws_instance.private_ip
}

output "vyos_external_ip" {
	value = aws_instance.aws_instance.public_ip
}
