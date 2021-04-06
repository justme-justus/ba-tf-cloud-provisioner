terraform {
	required_providers {
		azurerm = {
			source  = "hashicorp/azurerm"
			version = "=2.52.0"
		}
	}
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
	features {}
}

resource "time_static" "creation_time" {}

resource "azurerm_resource_group" "azure_rg" {
	name     = "created_by_tf_on_${time_static.creation_time.unix}"
	# ToDo: Location as var in main.tf
	location = "North Europe"
}

output "azure_rg" {
	value = azurerm_resource_group.azure_rg.name
}
