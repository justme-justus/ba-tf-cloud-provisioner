resource "local_file" "vyos_config" {

	filename = var.vyos_script_path
	content = templatefile("${path.module}/include/vyos_config.tpl",
	{
		aws_vgw_ip = var.aws_vgw_ip
		aws_tunnel1_psk = var.aws_tunnel1_psk
		aws_vpn_cgw_local = var.aws_vpn_cgw_local
		aws_peering_address = var.aws_peering_address
		azure_vgw_ip = var.azure_vgw_ip
		azure_peering_address = var.azure_peering_address
		azure_peering_address_local = var.azure_peering_address_local
		azure_tunnel1_psk = var.azure_tunnel1_psk
		as_number = var.as_number
		aws_as_number = var.aws_as_number
		azure_as_number = var.azure_as_number
	})
}

resource "null_resource" "vyos_config" {

	connection {
		type = "ssh"
		host = var.vyos_host
		user = var.ssh_user
		private_key = file(var.private_key_file)
		// ToDo
		// host_key = 
	}
	
	provisioner "file" {
		source = local_file.vyos_config.filename
		destination = var.vyos_script_path
	}
	
	provisioner "remote-exec" {
		inline = [ "chmod +x ${var.vyos_script_path}", var.vyos_script_path ]
	}
	
	provisioner "local-exec" {
		command = "${path.module}/bin/save_last_manual_commit.sh"
	}
}
	
resource "null_resource" "vyos_config_destroy" {
	provisioner "local-exec" {
		when = destroy
		command = "${path.module}/bin/apply_last_manual_commit.sh"
	}
}
