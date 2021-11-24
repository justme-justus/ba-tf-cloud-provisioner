terraform {
        required_providers {
                phpipam = {
                        source = "lord-kyron/phpipam"
                        version = "~> 1.2.7"
                }
        }
}

provider "phpipam" {
        app_id = var.phpipam_app_id
        endpoint = var.phpipam_endpoint
        password = var.phpipam_password
        username = var.phpipam_username
        // Probably just needed for HTTPS
        insecure = true
}

//Azure
data "phpipam_section" "azure_main_section" {
	name = "TF_CLOUD_AS${var.azure_as_number}_AZURE"
}

data "phpipam_subnet" "azure_main_subnet" {
	section_id = data.phpipam_section.azure_main_section.section_id
	description_match = "AS${var.azure_as_number}: Azure"
}

resource "phpipam_first_free_subnet" "free_subnet_azure" {
	parent_subnet_id = data.phpipam_subnet.azure_main_subnet.subnet_id
	subnet_mask = 24
	// ToDo: Fix descriptions (global.vars)
	description = "AZURE_VPN_CLIENTS"
}


//AWS
data "phpipam_section" "aws_main_section" {
	name = "TF_CLOUD_AS${var.aws_as_number}_AWS"
}

data "phpipam_subnet" "aws_main_subnet" {
	section_id = data.phpipam_section.aws_main_section.section_id
	description_match = "AS${var.aws_as_number}: AWS"
}

resource "phpipam_first_free_subnet" "free_subnet_aws_client_transfer" {
	parent_subnet_id = data.phpipam_subnet.aws_main_subnet.subnet_id
	subnet_mask = 24
	description = "AWS_CLIENT_TRANSFER_VPC"
}

resource "phpipam_first_free_subnet" "free_subnet_aws_clients" {
	parent_subnet_id = data.phpipam_subnet.aws_main_subnet.subnet_id
	//why do I export and not import mask?
	subnet_mask = 24
	description = "AWS_VPN_CLIENTS"
}

//Local
#data "phpipam_section" "local_main_section" {
#	name = "TF_CLOUD_AS${var.local_as_number}_LOCAL"
#}
#
#data "phpipam_subnet" "local_main_subnet" {
#	section_id = data.phpipam_section.local_main_section.section_id
#	description_match = "AS${var.local_as_number}: Local"
#}
#
#resource "phpipam_first_free_subnet" "free_subnet_local_clients" {
#	parent_subnet_id = data.phpipam_subnet.local_main_subnet.subnet_id
#	subnet_mask = 24
#	description = "LOCAL_CLIENT_TRANSFER"
#}

#ToDo: Register IP addresses in IPAM

output "azure_vpn_clients_subnet" {
	value = phpipam_first_free_subnet.free_subnet_azure.subnet_address
}

output "azure_vpn_clients_subnet_mask" {
	value = phpipam_first_free_subnet.free_subnet_azure.subnet_mask
}

output "aws_vpn_client_transfer_subnet" {
	value = phpipam_first_free_subnet.free_subnet_aws_client_transfer.subnet_address
}

output "aws_vpn_client_transfer_subnet_mask" {
	value = phpipam_first_free_subnet.free_subnet_aws_client_transfer.subnet_mask
}

output "aws_vpn_clients_subnet" {
	value = phpipam_first_free_subnet.free_subnet_aws_clients.subnet_address
}

output "aws_vpn_clients_subnet_mask" {
	value = phpipam_first_free_subnet.free_subnet_aws_clients.subnet_mask
}

#output "local_vpn_clients_subnet" {
#	value = phpipam_first_free_subnet.free_subnet_local_clients.subnet_address
#}
#
#output "local_vpn_clients_subnet_mask" {
#	value = phpipam_first_free_subnet.free_subnet_local_clients.subnet_mask
#}
