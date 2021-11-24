resource "random_password" "random_password" {
	length = 24
	lower = true
	upper = true
	number = true
	special = false
}

output "azure_vyos_tunnel1_psk" {
	value = random_password.random_password.result
	sensitive = true
}
