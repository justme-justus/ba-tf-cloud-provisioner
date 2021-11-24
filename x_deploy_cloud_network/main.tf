/* Convention
Lines beginning with '#' exclude source code (HCL)
Lines beginning with '//' are single-line comments
Lines beginning with /* or ending with *\/ are multi-line comments 

UPPER_CASE variables are inherited from environment
CamelCase variables are inherited from *tfvars
lower_case variables are terraform runtime variables
*/

module "time_static" {
	source = "./modules/time_static"
}

module "generate_psk" {
	source = "./modules/generate_psk"
}

module "ipam" {
	source = "./modules/ipam"

	phpipam_app_id = var.PHPIPAM_APP_ID
	phpipam_endpoint = var.PHPIPAM_ENDPOINT
	phpipam_password = var.PHPIPAM_PASSWORD
	phpipam_username = var.PHPIPAM_USERNAME

	aws_as_number = var.AwsAs
	azure_as_number = var.AzureAs
	vyos_as_number = var.VyosAs
}

module "azure" {
	source = "./modules/azure"
	
	// second (first usable) address in transfer network /30 as aws peering address, hostnum = {0,..,n-1}
	aws_peering_address = cidrhost("${module.ipam.apipa_peering_subnet}/30", 1)
	// third address in transfer network /30 as azure peering address
	peering_address = cidrhost("${module.ipam.apipa_peering_subnet}/30", 2)
	subnet = module.ipam.azure_subnet
	subnet_mask = module.ipam.azure_subnet_mask
	main_subnet = module.ipam.azure_main_subnet
	main_subnet_mask = module.ipam.azure_main_subnet_mask
	aws_vgw_ip = module.aws.azure_vpn_outside_ip
	aws_tunnel1_psk = module.aws.azure_vpn_tunnel1_psk
	vyos_peering_address = cidrhost("${module.ipam.apipa_peering_subnet_vyos_azure}/30", 1)
	vyos_azure_peering_address = cidrhost("${module.ipam.apipa_peering_subnet_vyos_azure}/30", 2)
	vyos_azure_peering_subnet = "${module.ipam.apipa_peering_subnet_vyos_azure}/30"
	creation_time_epoch = module.time_static.current_time_epoch
	vyos_tunnel1_psk = module.generate_psk.azure_vyos_tunnel1_psk
	as_number = var.AzureAs
	aws_as_number = var.AwsAs
	vyos_as_number = var.VyosAs
}

module "aws" {
	source = "./modules/aws"

	#azure_peering_address = cidrhost("${module.ipam.apipa_peering_subnet}/30", 1)
	azure_peering_subnet = "${module.ipam.apipa_peering_subnet}/30"
	azure_vgw_ip = module.azure.azure_vgw_ip
	#azure_peering_address = cidrhost("${module.ipam.apipa_peering_subnet}/30", 2)
	subnet = module.ipam.aws_subnet
	subnet_mask = module.ipam.aws_subnet_mask
	#main_subnet = module.ipam.aws_main_subnet
	#main_subnet_mask = module.ipam.aws_main_subnet_mask
	vyos_vgw_ip = var.VyosExternalIp
	as_number = var.AwsAs
	azure_as_number = var.AzureAs
	vyos_as_number = var.VyosAs
}

#module "vyos" {
#	source = "./modules/vyos"
#	
#	aws_vgw_ip = module.aws.vyos_vpn_outside_ip
#	aws_tunnel1_psk = module.aws.vyos_vpn_tunnel1_psk
#	#Fix var, something like vyos_cgw_ip
#	aws_vpn_cgw_local = module.aws.vyos_vpn_cgw
#	#Fix var... vyos_vgw_ip
#	aws_peering_address = module.aws.vyos_vpn_vgw
#	azure_vgw_ip = module.azure.azure_vgw_ip
#	#azure_vyos_psk = module.azure.azure_vyos_psk
#	azure_peering_address_local = cidrhost("${module.ipam.apipa_peering_subnet_vyos_azure}/30", 1)
#	azure_peering_subnet = "${module.ipam.apipa_peering_subnet_vyos_azure}/30"
#	// re-use transfer net from AWS - AZURE and static route... Azure VGW can only hold one APIPA
#	azure_peering_address = cidrhost("${module.ipam.apipa_peering_subnet}/30", 2)
#
#	private_key_file = var.PrivateKeyFile
#	ssh_user = var.SshUser
#	vyos_host = var.VyosHost
#	vyos_script_path = "/tmp/${module.time_static.current_time_epoch}"
#	azure_tunnel1_psk = module.generate_psk.azure_vyos_tunnel1_psk
#	as_number = var.VyosAs
#	aws_as_number = var.AwsAs
#	azure_as_number = var.AzureAs
#}

output "vpc_id" {
	# passthrough output to root module for remote_state import
	value = module.aws.vpc_id
}

output "aws_subnet_id" {
	value = module.aws.subnet_id
}

output "tg_id" {
	value = module.aws.tg_id
}

output "tg_default_rt_id" {
	value = module.aws.tg_default_rt_id
}

output "vpc_main_rt" {
	value = module.aws.vpc_main_rt
}

output "azure_subnet_id" {
	value = module.azure.subnet_id
}

output "azure_rg_name" {
	value = module.azure.rg_name
}

output "azure_rg_location" {
	value = module.azure.rg_location
}

output "azure_gw_subnet_id" {
	value = module.azure.gw_subnet_id
}
#output "creation_time" {
#	value = module.time_static.current_time_epoch
#}
