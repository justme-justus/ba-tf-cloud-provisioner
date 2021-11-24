terraform {
	required_providers {
		azurerm = {
			source	= "hashicorp/azurerm"
			version = "=2.52.0"
		}
	}
}

provider "azurerm" {
	features {}
}

resource "azurerm_resource_group" "azurerm_resource_group" {
	name = "rg_tf_${var.creation_time_epoch}"
	location = "North Europe"
}

resource "azurerm_virtual_network" "azurerm_virtual_network" {
	name = "vnet_tf_${var.creation_time_epoch}"
	location = azurerm_resource_group.azurerm_resource_group.location
	resource_group_name = azurerm_resource_group.azurerm_resource_group.name
	address_space = [ "${var.main_subnet}/${var.main_subnet_mask}" ]
	dns_servers = [ "10.0.0.4", "10.0.0.5" ]
}

resource "azurerm_subnet" "azurerm_subnet" {
	name = "subnet_tf_${var.creation_time_epoch}"
	virtual_network_name = azurerm_virtual_network.azurerm_virtual_network.name
	resource_group_name = azurerm_resource_group.azurerm_resource_group.name
	address_prefixes = ["${var.subnet}/${var.subnet_mask}"]
}

resource "azurerm_public_ip" "azurerm_public_ip" {
	name = "public_ip_tf_${var.creation_time_epoch}"
        location = azurerm_resource_group.azurerm_resource_group.location
        resource_group_name = azurerm_resource_group.azurerm_resource_group.name
	//design decision: Dynamic IP gets allocated by the moment a "machine" gets provisioned. Static is allocated with this ressource. If mode "Dynamic": get allocated IP with "data "azurerm_public_ip"". VPN Gateway is Dynamic only.
	allocation_method = "Dynamic"
	sku = "Basic"
}

resource "azurerm_subnet" "gateway_subnet" {
	// don't rename: https://github.com/terraform-providers/terraform-provider-azurerm/issues/875
	name = "GatewaySubnet"
        resource_group_name = azurerm_resource_group.azurerm_resource_group.name
	virtual_network_name = azurerm_virtual_network.azurerm_virtual_network.name
	address_prefixes = [ "10.32.67.0/27" ]
}

resource "azurerm_virtual_network_gateway" "azurerm_virtual_network_gateway" {
	name = "test"
        location = azurerm_resource_group.azurerm_resource_group.location
        resource_group_name = azurerm_resource_group.azurerm_resource_group.name

	type = "Vpn"
	vpn_type = "RouteBased"

	active_active = false
	enable_bgp = true
	sku = "VpnGw1"

	ip_configuration {
		name = "vnetGatewayConfig"
		public_ip_address_id = azurerm_public_ip.azurerm_public_ip.id
		private_ip_address_allocation = "Dynamic"
		subnet_id = azurerm_subnet.gateway_subnet.id
	}
	bgp_settings {
		asn = var.as_number
		peering_addresses {
			apipa_addresses = [ var.peering_address ]
		}
	}
}

resource "azurerm_local_network_gateway" "to_aws" {
	name = "to_aws"
        location = azurerm_resource_group.azurerm_resource_group.location
        resource_group_name = azurerm_resource_group.azurerm_resource_group.name
	gateway_address = var.aws_vgw_ip
#	address_space = [ "${var.peering_address}/32" ]

	bgp_settings {
		asn = var.aws_as_number
		bgp_peering_address = var.aws_peering_address
	}
}

resource "azurerm_virtual_network_gateway_connection" "to_aws" {
	name = "to_aws"
        location = azurerm_resource_group.azurerm_resource_group.location
        resource_group_name = azurerm_resource_group.azurerm_resource_group.name

	type = "IPsec"
	virtual_network_gateway_id = azurerm_virtual_network_gateway.azurerm_virtual_network_gateway.id
	local_network_gateway_id = azurerm_local_network_gateway.to_aws.id

	shared_key = var.aws_tunnel1_psk
	enable_bgp = true
}

resource "azurerm_local_network_gateway" "to_vyos" {
	name = "to_vyos"
        location = azurerm_resource_group.azurerm_resource_group.location
        resource_group_name = azurerm_resource_group.azurerm_resource_group.name
	gateway_address = "195.244.254.198"
#	address_space = [ "${var.vyos_peering_address}/32" ]

	bgp_settings {
		asn = var.vyos_as_number
		bgp_peering_address = var.vyos_peering_address
	}
}

resource "azurerm_virtual_network_gateway_connection" "to_vyos" {
	name = "to_vyos"
        location = azurerm_resource_group.azurerm_resource_group.location
        resource_group_name = azurerm_resource_group.azurerm_resource_group.name

	type = "IPsec"
	virtual_network_gateway_id = azurerm_virtual_network_gateway.azurerm_virtual_network_gateway.id
	local_network_gateway_id = azurerm_local_network_gateway.to_vyos.id
	shared_key = var.vyos_tunnel1_psk
	enable_bgp = true
}

output "azure_vgw_ip" {
	value = azurerm_public_ip.azurerm_public_ip.ip_address
}

output "subnet_id" {
	value = azurerm_subnet.azurerm_subnet.id
}

output "rg_name" {
	value = azurerm_resource_group.azurerm_resource_group.name
}

output "rg_location" {
	value = azurerm_resource_group.azurerm_resource_group.location
}

output "gw_subnet_id" {
	value = azurerm_subnet.gateway_subnet.id
}
