/* Convention
Lines beginning with '#' exclude source code (HCL)
Lines beginning with '//' are single-line comments
Lines beginning with /* or ending with *\/ are multi-line comments 

UPPER_CASE variables are inherited from environment
CamelCase variables are inherited from *tfvars
lower_case variables are terraform runtime variables
*/

data "terraform_remote_state" "base_deployment" {
  backend = "local"

  config = {
    path = "../2_deploy_cloud_network/terraform.tfstate"
  }
}

module "ipam"{
        source = "./modules/ipam"
        phpipam_app_id = var.PHPIPAM_APP_ID
        phpipam_endpoint = var.PHPIPAM_ENDPOINT
        phpipam_password = var.PHPIPAM_PASSWORD
        phpipam_username = var.PHPIPAM_USERNAME

        aws_as_number = var.AwsAs
        azure_as_number = var.AzureAs
	//"Local AS" is less specific
        local_as_number = var.LocalAs

}

module "aws" {
        source = "./modules/aws"
	#remote state import
	transit_gateway_id = data.terraform_remote_state.base_deployment.outputs.tg_id
	vpc_main_rt_id = data.terraform_remote_state.base_deployment.outputs.vpc_main_rt
	tg_default_rt_id = data.terraform_remote_state.base_deployment.outputs.tg_default_rt_id
	vpn_clients_subnet = module.ipam.aws_vpn_clients_subnet
	vpn_clients_subnet_mask = module.ipam.aws_vpn_clients_subnet_mask
	vpn_client_transfer_subnet = module.ipam.aws_vpn_client_transfer_subnet
	vpn_client_transfer_subnet_mask = module.ipam.aws_vpn_client_transfer_subnet_mask
}

module "azure" {
        source = "./modules/azure"
	#remote state import
	rg_location = data.terraform_remote_state.base_deployment.outputs.azure_rg_location
	rg_name = data.terraform_remote_state.base_deployment.outputs.azure_rg_name
	subnet_id = data.terraform_remote_state.base_deployment.outputs.azure_subnet_id
	gw_subnet_id = data.terraform_remote_state.base_deployment.outputs.azure_gw_subnet_id
	azure_vpn_clients_subnet = module.ipam.azure_vpn_clients_subnet
	azure_vpn_clients_subnet_mask = module.ipam.azure_vpn_clients_subnet_mask
}

module "aws_vyos" {
	source = "./modules/aws_vyos"
	aws_vpn_clients_subnet = module.ipam.aws_vpn_clients_subnet
	aws_vpn_clients_subnet_mask = module.ipam.aws_vpn_clients_subnet_mask
	vyos_internal_ip = module.aws.vyos_internal_ip
	vyos_user = var.VyosUser
	private_key_file = var.PrivateKeyFile
}


//avoid timing issues after creation: maybe we need to wait until machine is properly booted
module "azure_vyos" {
        source = "./modules/azure_vyos"

	vyos_internal_ip = module.azure.vyos_internal_ip
	azure_vpn_clients_subnet = module.ipam.azure_vpn_clients_subnet
	azure_vpn_clients_subnet_mask = module.ipam.azure_vpn_clients_subnet_mask
	vyos_user = var.VyosUser
	private_key_file = var.PrivateKeyFile
}

module "aws_webserver" {
        source = "./modules/aws_webserver"
	aws_main_vpc = data.terraform_remote_state.base_deployment.outputs.vpc_id
	aws_main_vpc_subnet = data.terraform_remote_state.base_deployment.outputs.aws_subnet_id
	private_key_file = var.PrivateKeyFile
}

module "azure_webserver" {
        source = "./modules/azure_webserver"
	rg_location = data.terraform_remote_state.base_deployment.outputs.azure_rg_location
	rg_name = data.terraform_remote_state.base_deployment.outputs.azure_rg_name
	subnet_id = data.terraform_remote_state.base_deployment.outputs.azure_subnet_id
	private_key_file = var.PrivateKeyFile
}

module "azure_client" {
	source = "./modules/azure_client"
        private_key_file = var.PrivateKeyFile
}

module "aws_client" {
	source = "./modules/aws_client"
	//key_name = "key_automation"
        private_key_file = var.PrivateKeyFile
}

module "dns_update" {
        source = "./modules/dns_update"
	dublin_ip = module.azure.vyos_external_ip
	frankfurt_ip = module.aws.vyos_external_ip
	kiel_ip = "195.244.254.197"
	frankfurt_www_internal_ip = module.aws_webserver.www_private_ip
	dublin_www_internal_ip = module.azure_webserver.www_private_ip
	dublin_client_ip = module.azure_client.client_public_ip
	frankfurt_client_ip = module.aws_client.client_public_ip
	aws_vyos_internal_ip = module.aws.vyos_internal_ip
	azure_vyos_internal_ip = module.azure.vyos_internal_ip
}
