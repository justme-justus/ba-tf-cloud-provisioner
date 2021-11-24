data "aws_ami" "ubuntu" {
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

resource "aws_network_interface" "aws_network_interface" {
	subnet_id   = var.aws_main_vpc_subnet
}

resource "aws_security_group" "aws_security_group" {
        name        = "allow_rfc_inbound_any_and_outbound_any"
        description = "Allow RFC addresses inbound traffic, allow any outbound"
        vpc_id      = var.aws_main_vpc

        ingress {
                description      = "10./8 and 192.168./16"
                from_port        = 0
                to_port          = 0
                protocol         = "-1"
                cidr_blocks      = [ "10.0.0.0/8", "192.168.0.0/16" ]
        }
        egress {
                from_port        = 0
                to_port          = 0
                protocol         = "-1"
                cidr_blocks      = ["0.0.0.0/0"]
        }
}

resource "aws_instance" "aws_instance" {
	ami = data.aws_ami.ubuntu.id
	instance_type = "t3.micro"
	key_name = "key_automation"
	vpc_security_group_ids = [ aws_security_group.aws_security_group.id ]
	subnet_id   = var.aws_main_vpc_subnet
}

// too many connection retries after creation
//resource "time_sleep" "wait_30_seconds" {
//	depends_on = [ aws_instance.aws_instance ]
//	create_duration = "30s"
//}

resource "null_resource" "www_config" {
//	depends_on = [ time_sleep.wait_30_seconds ]
        connection {
                type = "ssh"
		host = aws_instance.aws_instance.private_ip
                //reference user in aws config?
                user = "ubuntu"
                private_key = file(var.private_key_file)
                // ToDo
                // host_key =
        }

        provisioner "remote-exec" {
                inline = [ "sudo http_proxy=\"http://192.168.201.1:8080\" apt install -y apache2", "sudo sed -i 's/It works!/It works! @AWS Cloud (Location: Frankfurt)/' /var/www/html/index.html" ]
        }
}

output "www_private_ip" {
	value = aws_instance.aws_instance.private_ip
}
