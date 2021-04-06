variable "aws_vgw_ip" {}
variable "aws_tunnel1_psk" {}
variable "aws_vpn_cgw_local" {}
variable "aws_peering_address" {}
variable "azure_peering_address" {}
variable "azure_peering_subnet" {}
variable "azure_peering_address_local" {}
variable "azure_vgw_ip" {}
#static key:   shared_key = "GeCxfLgpOnrEjzFn88rx1hdn9ZqgvxW"
variable "azure_tunnel1_psk" {}

#auto.vars
variable "private_key_file" {}
variable "ssh_user" {}
variable "vyos_host" {}
variable "vyos_script_path" {}
variable "as_number" {}
variable "aws_as_number" {}
variable "azure_as_number" {}
