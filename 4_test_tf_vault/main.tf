variable VAULT_USERNAME {}
variable VAULT_PASSWORD {}


provider "vault" {
  auth_login {
    path = "auth/userpass/login/${var.VAULT_USERNAME}"

    parameters = {
      password = var.VAULT_PASSWORD
    }
  }
}

#resource "vault_generic_secret" "example" {
#  path = "kv/foo"
#
#  data_json = <<EOT
#{
#  "foo":   "bar",
#  "pizza": "cheese"
#}
#EOT
#}

resource "vault_pki_secret_backend_cert" "app" {
#  depends_on = [ "vault_pki_secret_backend_role.admin" ]

#  backend = "${vault_pki_secret_backend.intermediate.path}"
#  name = "${vault_pki_secret_backend_role.test.name}"
  #backend = "pki_int"
  #name = "test_pki_role"
  backend = "pki"
  name = "test"

  common_name = "bla.ba.mungard.de"
}

resource "vault_pki_secret_backend_cert" "client-cert" {
#  depends_on = [ "vault_pki_secret_backend_role.admin" ]

#  backend = "${vault_pki_secret_backend.intermediate.path}"
#  name = "${vault_pki_secret_backend_role.test.name}"
  backend = "pki"
  name = "test"

  common_name = "ovpn-test.ba.mungard.de"
}
