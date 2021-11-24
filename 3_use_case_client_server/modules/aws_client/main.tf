resource "aws_vpc" "aws_vpc" {
	cidr_block = "10.43.0.0/16"
	
	tags = {
		Name = "tf-example"
	}
}

resource "aws_subnet" "aws_subnet" {
	vpc_id            = aws_vpc.aws_vpc.id
	cidr_block        = "10.43.0.0/24"
	map_public_ip_on_launch = true
	
	tags = {
		Name = "tf-example"
	}
}

resource "aws_internet_gateway" "aws_internet_gateway" {
        vpc_id = aws_vpc.aws_vpc.id
}

resource "aws_route" "aws_route" {
        destination_cidr_block = "0.0.0.0/0"
        route_table_id = aws_vpc.aws_vpc.main_route_table_id
	gateway_id = aws_internet_gateway.aws_internet_gateway.id
}

resource "aws_security_group" "aws_security_group" {
        name        = "allow_SSH_inbound_and_any_outbound"
        description = "Allow RFC addresses inbound traffic, allow any outbound"
        vpc_id      = aws_vpc.aws_vpc.id

        ingress {
                description      = "any inbound"
                from_port        = 0
                to_port          = 22
                protocol         = "tcp"
                cidr_blocks      = [ "0.0.0.0/0" ]
        }
        egress {
                from_port        = 0
                to_port          = 0
                protocol         = "-1"
                cidr_blocks      = ["0.0.0.0/0"]
        }
}

resource "aws_network_interface" "aws_network_interface" {
	subnet_id   = aws_subnet.aws_subnet.id
	private_ips = ["10.43.0.100"]
	security_groups = [ aws_security_group.aws_security_group.id ]
	
	tags = {
		Name = "primary_network_interface"
	}
}

data "aws_ami" "aws_ami" {
	most_recent = true
	
	filter {
		name   = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
	}
	
	filter {
		name   = "virtualization-type"
		values = ["hvm"]
	}
	
	owners = ["099720109477"] # Canonical
}

resource "aws_instance" "aws_instance" {
	ami = data.aws_ami.aws_ami.id
	instance_type = "t3.micro"
	//replace by var
	key_name = "key_automation"

	network_interface {
		network_interface_id = aws_network_interface.aws_network_interface.id
		device_index         = 0
	}

	tags = {
		Name = "tf_test"
	}
}

resource "null_resource" "www_config" {
        // Dynamic addresses get allocated on machine creation
        depends_on = [ aws_instance.aws_instance ]
        connection {
                type = "ssh"
                host = aws_instance.aws_instance.public_ip
                //reference user in azure config?
                user = "ubuntu"
                private_key = file(var.private_key_file)
                // ToDo
                // host_key =
        }
	
        provisioner "file" {
		//VAR
                source = "/home/justus/terraform/.cred_mgmt/_push/openvpn/aws_client/config.ovpn"
                destination = "/home/ubuntu/config.ovpn"
        }

        provisioner "remote-exec" {
                //openvpn && openvpn-systemd-resolve && config push
                inline = 	[
				"sudo apt update",
				"sudo apt install -y lynx openvpn openvpn-systemd-resolved iperf3"
				]
        }
}

output "client_public_ip" {
	value = aws_instance.aws_instance.public_ip
}
