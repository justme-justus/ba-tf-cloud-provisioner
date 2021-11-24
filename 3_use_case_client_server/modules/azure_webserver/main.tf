terraform {
        required_providers {
                azurerm = {
                        source  = "hashicorp/azurerm"
                        version = "~> 2.52.0"
                }
        }
}

provider "azurerm" {
        features {}
}

resource "azurerm_network_interface" "azurerm_network_interface" {
	name                = "www-server-nic"
	location            = var.rg_location
	resource_group_name = var.rg_name

	ip_configuration {
		name                          = "www-server-ipconfig"
		subnet_id                     = var.subnet_id
		private_ip_address_allocation = "Dynamic"
	}
}

resource "azurerm_virtual_machine" "azurerm_virtual_machine" {
	name                  = "www-vm"
	location            = var.rg_location
	resource_group_name = var.rg_name
	network_interface_ids = [ azurerm_network_interface.azurerm_network_interface.id ]
	vm_size               = "Standard_DS1_v2"

	delete_os_disk_on_termination = true
	delete_data_disks_on_termination = true

	storage_image_reference {
		publisher = "Canonical"
		offer     = "UbuntuServer"
		sku       = "18.04-LTS"
		version   = "latest"
	}

	storage_os_disk {
		name              = "ubuntu-disk1"
		caching           = "ReadWrite"
		create_option     = "FromImage"
		managed_disk_type = "Standard_LRS"
	}

	os_profile {
		computer_name  = "hostname"
		admin_username = "ubuntu"
	}

	os_profile_linux_config {
		disable_password_authentication = true
		ssh_keys {
			path = "/home/ubuntu/.ssh/authorized_keys"
			key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCa7VVxduiq6nvkwhnF5agZ8k7L9L6eoFjTw2T+oRj03Wws+YNbjdfdeukxrRH/zooGVjnU8fa/G7lFPB29tU2++kbgI0cElSEvAi8CPkeD5vz4MmG9S78s6NEeV4PyrdpFPON3cwG5n50q2zljzRGvOM0N09zok/WQfull5ODJ5czEPJcPf8xi45BHS8AZ+Lyg7jouFNMxTbyf9T0ZGiL4niPhc5eVa/T1yb6KPLd9FC34P/qgacHGzI9MoK2mth+eGD0LpZHAMAeSpy4oONGar9CO6qaD0G8AVNm8nZVCdG4WIF6ZoQ0r2zlsQ2DCfB1oz/Y/8Cd+fRFIeYkXycmxq7ysn4u2PlGqHD1My9MgGkX9eATdjF/nRdhjTHpBjGJ/xYqUJCPoUcpUg8WfY4HoKHmJYxaV6j/pZHUYe8VQgf6AnvMFauSMhK8gF30/5T+CuQT1go9sLFSHUCgYnni77vYO3XAHC4OxYfMgJAR9W6MMV2YRCgSx0BwM0q672ogQbPWOdnKV//IwcIrQfhgyi7lMoq3YFDesQVgPQeJ2lQsaiFrWxmU+mvV4vv3PTg55GrtYpGqSckgR5kyWRSP2vWBBh6wfGJQXkxmTZbHfIILB7o6lGjVKjDQfODmMdX6bueew1nknvsVAw2QaHjnqTXCVIouFl7Akh1w9g5fapw== justus@tf"
		}
	}
}

resource "null_resource" "www_config" {
	// Dynamic addresses get allocated on machine creation
	depends_on = [ azurerm_virtual_machine.azurerm_virtual_machine ]
        connection {
                type = "ssh"
                host = azurerm_network_interface.azurerm_network_interface.private_ip_address
                //reference user in azure config?
                user = "ubuntu"
                private_key = file(var.private_key_file)
                // ToDo
                // host_key =
        }

        provisioner "remote-exec" {
                inline = [ "sudo http_proxy=\"http://192.168.201.1:8080\" apt update",
			   "sudo http_proxy=\"http://192.168.201.1:8080\" apt install -y apache2",
			   "sudo sed -i 's/It works!/It works! @Azure Cloud (Location: \"North Europe - Dublin\")/' /var/www/html/index.html" ]
        }
}

output "www_private_ip" {
	value = azurerm_network_interface.azurerm_network_interface.private_ip_address
}

