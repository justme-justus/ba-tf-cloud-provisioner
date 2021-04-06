terraform {
	required_providers {
		phpipam = {
			source = "lord-kyron/phpipam"
			version = "1.2.7"
		}
	}
}

provider "phpipam" {
        app_id = var.phpipam_app_id
        endpoint = var.phpipam_endpoint
        password = var.phpipam_password
        username = var.phpipam_username
	// Probably just needed for HTTPS
	#insecure = true
}

//Azure
data "phpipam_section" "azure_master_section" {
	name = "TF_CLOUD_AS${var.azure_as_number}_AZURE"
}

data "phpipam_subnet" "azure_master_subnet" {
	section_id = data.phpipam_section.azure_master_section.section_id
	description_match = "AS${var.azure_as_number}: Azure"
}

resource "phpipam_first_free_subnet" "free_subnet_azure" {
	parent_subnet_id = data.phpipam_subnet.azure_master_subnet.subnet_id
	subnet_mask = 24
	description = "VNET_XY_UUID"
}
//Azure - AWS Transfer
data "phpipam_section" "apipa_master_section" {
	name = "TF_CLOUD_BGP_TRANSFER"
}

data "phpipam_subnet" "apipa_transfer_subnet" {
	section_id = data.phpipam_section.apipa_master_section.section_id
	description_match = "Cloud_Transfer_BGP_1"
}

resource "phpipam_first_free_subnet" "free_subnet_apipa" {
	parent_subnet_id = data.phpipam_subnet.apipa_transfer_subnet.subnet_id
	subnet_mask = 30
	description = "BGP_XY"
}

resource "phpipam_first_free_subnet" "free_subnet_apipa_vyos" {
	parent_subnet_id = data.phpipam_subnet.apipa_transfer_subnet.subnet_id
	subnet_mask = 30
	description = "BGP_VYOS_AZURE"
}

//AWS
data "phpipam_section" "aws_master_section" {
	name = "TF_CLOUD_AS${var.aws_as_number}_AWS"
}

data "phpipam_subnet" "aws_master_subnet" {
	section_id = data.phpipam_section.aws_master_section.section_id
	description_match = "AS${var.aws_as_number}: AWS"
}

resource "phpipam_first_free_subnet" "free_subnet_aws" {
	parent_subnet_id = data.phpipam_subnet.aws_master_subnet.subnet_id
	subnet_mask = 24
	description = "VPC_XY_UUID"
}
#first address for AWS BGP

output "apipa_peering_subnet" {
	value = phpipam_first_free_subnet.free_subnet_apipa.subnet_address
}

output "apipa_peering_subnet_vyos_azure" {
	value = phpipam_first_free_subnet.free_subnet_apipa_vyos.subnet_address
}

#ToDo: Register IP addresses in IPAM

output "azure_master_subnet" {
	value = data.phpipam_subnet.azure_master_subnet.subnet_address
}

output "azure_master_subnet_mask" {
	value = data.phpipam_subnet.azure_master_subnet.subnet_mask
}

output "azure_subnet" {
	value = phpipam_first_free_subnet.free_subnet_azure.subnet_address
}

output "azure_subnet_mask" {
	value = phpipam_first_free_subnet.free_subnet_azure.subnet_mask
}

output "aws_master_subnet" {
	value = data.phpipam_subnet.aws_master_subnet.subnet_address
}

output "aws_master_subnet_mask" {
	value = data.phpipam_subnet.aws_master_subnet.subnet_mask
}

output "aws_subnet" {
	value = phpipam_first_free_subnet.free_subnet_aws.subnet_address
}

output "aws_subnet_mask" {
	value = phpipam_first_free_subnet.free_subnet_aws.subnet_mask
}
