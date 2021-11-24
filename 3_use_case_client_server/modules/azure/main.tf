terraform {
	required_providers {
		azurerm = {
			source	= "hashicorp/azurerm"
			version = "~> 2.52.0"
		}
	}
}

provider "azurerm" {
	features {}
}

resource "azurerm_route_table" "azurerm_route_table" {
	name                          = "Test_RT"
	location                      = var.rg_location
	resource_group_name           = var.rg_name
	disable_bgp_route_propagation = false

	route {
		name = "OpenVPN_Client"
		// fix: get actual subnet from IPAM ("next free")
		address_prefix = "${var.azure_vpn_clients_subnet}/${var.azure_vpn_clients_subnet_mask}"
		//geht evtl. einfacher
		next_hop_type  = "VirtualAppliance"
		next_hop_in_ip_address = azurerm_linux_virtual_machine.azurerm_linux_virtual_machine.private_ip_address
	}
}

resource "azurerm_subnet_route_table_association" "client_vpn_to_vyos_local_subnet" {
	subnet_id = var.subnet_id
	route_table_id = azurerm_route_table.azurerm_route_table.id
}

resource "azurerm_subnet_route_table_association" "client_vpn_to_vyos_gateway_subnet" {
	subnet_id = var.gw_subnet_id
	route_table_id = azurerm_route_table.azurerm_route_table.id
}

resource "azurerm_public_ip" "azurerm_public_ip" {
	name  = "vyos_public_ip"
	location = var.rg_location
	resource_group_name = var.rg_name
	allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "azurerm_network_interface" {
name = "vyos-nic"
	location = var.rg_location
	resource_group_name = var.rg_name
	//disable "rpf" check to enable ip routing
	enable_ip_forwarding = true
	ip_configuration {
		name = "test-internal"
		subnet_id = var.subnet_id
		private_ip_address_allocation = "Dynamic"
		public_ip_address_id =  azurerm_public_ip.azurerm_public_ip.id
	}
}

resource "azurerm_network_security_group" "azurerm_network_security_group" {
  	name = "Test-NSG"
	location = var.rg_location
	resource_group_name = var.rg_name
}

resource "azurerm_network_security_rule" "nsg_ssh_in" {
	resource_group_name = var.rg_name
	network_security_group_name = azurerm_network_security_group.azurerm_network_security_group.name
	//Allow SSH via RFC IP
	name = "SSH_IN"
	priority = 100
	direction = "Inbound"
	access = "Allow"
	protocol = "Tcp"
	source_port_range = "*"
	destination_port_range = "22"
	source_address_prefix = "192.168.0.0/24"
	destination_address_prefix = "*"
}
resource "azurerm_network_security_rule" "nsg_iperf_in" {
	resource_group_name = var.rg_name
	network_security_group_name = azurerm_network_security_group.azurerm_network_security_group.name
	//Allow SSH via RFC IP
	name = "IPERF_IN"
	priority = 150
	direction = "Inbound"
	access = "Allow"
	protocol = "Tcp"
	source_port_range = "*"
	destination_port_range = "5201"
	source_address_prefixes = [ "10.0.0.0/8", "192.168.0.0/24" ]
	destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "nsg_ovpn_in" {
	resource_group_name = var.rg_name
	network_security_group_name = azurerm_network_security_group.azurerm_network_security_group.name
	//Allow OVPN globally
	name = "OVPN_IN"
	priority = 200
	direction = "Inbound"
	access = "Allow"
	protocol = "Udp"
	source_port_range = "*"
	destination_port_range = "61231"
	source_address_prefix = "0.0.0.0/0"
	destination_address_prefix = "*"
}

resource "azurerm_network_interface_security_group_association" "azurerm_network_interface_security_group_association" {
	network_interface_id = azurerm_network_interface.azurerm_network_interface.id
	network_security_group_id = azurerm_network_security_group.azurerm_network_security_group.id
}

resource "azurerm_linux_virtual_machine"  "azurerm_linux_virtual_machine" {
	depends_on = [ azurerm_network_interface_security_group_association.azurerm_network_interface_security_group_association ]
	name = "vyos-test"
	location = var.rg_location
	resource_group_name = var.rg_name
	admin_username = "vyos"
	size = "Standard_B1s"
	network_interface_ids = [ azurerm_network_interface.azurerm_network_interface.id ]
	os_disk {
		caching = "ReadWrite"
		storage_account_type = "Premium_LRS"
	}
	// Better: Store Key in Resource Group in initial deployment and refernce it?
	admin_ssh_key {
 		username   = "vyos"
 		public_key = file("~/terraform/.cred_mgmt/_push/authorized_keys/id_rsa_automation.pub")
	}
	// $ az vm image list --publisher "Sentrium" --all --output table
	// $ az vm image list-skus --location westus --offer vyos-1-2-lts-on-azure --publisher sentriumsl
	source_image_reference {
		publisher = "sentriumsl"
		offer = "vyos-1-2-lts-on-azure"
		version = "latest"
		#sku = "vyos-router-on-azure"
		sku = "vyos-1-2-crux"
	}
	// https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
	// $ az vm image show --urn sentriumsl:vyos-1-2-lts-on-azure:vyos-router-on-azure:latest
	// $ az vm image show --urn sentriumsl:vyos-1-2-lts-on-azure:vyos-1-2-crux:latest
	plan {
		#name = "vyos-router-on-azure"
		#product = "vyos-1-2-lts-on-azure"
		name = "vyos-1-2-crux"
		product = "vyos-1-2-lts-on-azure"
		publisher = "sentriumsl"
	}
}

output "vyos_internal_ip" {
	value = azurerm_linux_virtual_machine.azurerm_linux_virtual_machine.private_ip_address
}

output "vyos_external_ip" {
	value = azurerm_linux_virtual_machine.azurerm_linux_virtual_machine.public_ip_address
}
