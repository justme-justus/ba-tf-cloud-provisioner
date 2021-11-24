resource "local_file" "vyos_config" {

	#filename = var.vyos_script_path
	filename = "/tmp/test2.sh"
	content = templatefile("${path.module}/include/vyos_config.tpl",
	{
		aws_vpn_clients_subnet = var.aws_vpn_clients_subnet
		aws_vpn_clients_subnet_mask = var.aws_vpn_clients_subnet_mask
	})
}

resource "null_resource" "vyos_config" {

	connection {
		type = "ssh"
		host = var.vyos_internal_ip
		//reference user in aws config?
		user = var.vyos_user
		private_key = file(var.private_key_file)
		// ToDo
		// host_key = 
	}
	
	provisioner "file" {
		#source = local_file.vyos_config.filename
		#destination = var.vyos_script_path
		source = "/tmp/test2.sh"
		destination = "/tmp/test2.sh"
	}
	
	provisioner "file" {
		#ToDo: replace by vars
		source = "/home/justus/terraform/.cred_mgmt/_push/openvpn/BA_CA_2021.crt"
		destination = "/config/auth/BA_CA_2021.crt"
	}

	provisioner "file" {
		#ToDo: replace by vars
		source = "/home/justus/terraform/.cred_mgmt/_push/openvpn/aws/vpn-server-aws.ba.mungard.de.crt"
		destination = "/config/auth/vpn-server-aws.ba.mungard.de.crt"
	}

	provisioner "file" {
		#ToDo: replace by vars
		source = "/home/justus/terraform/.cred_mgmt/_push/openvpn/aws/vpn-server-aws.ba.mungard.de.key"
		destination = "/config/auth/vpn-server-aws.ba.mungard.de.key"
	}

	provisioner "remote-exec" {
		#inline = [ "chmod +x ${var.vyos_script_path}", var.vyos_script_path ]
		inline = [ "chmod +x /tmp/test2.sh", "/tmp/test2.sh" ]
	}
}
