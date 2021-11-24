provider "dns" {
	alias = "dns-frankfurt"
	update {
		server        = "192.168.200.29"
		key_name      = "fr-vpn.ba.mungard.de."
		// $ tsig-keygen
		key_algorithm = "hmac-sha256"
		key_secret    = "qmifEVffPyN/BGaohFpyWPzBMIw5kBXKIfjYs3aIkRw="
	}
}

resource "dns_a_record_set" "vpn-frankfurt" {
	provider = dns.dns-frankfurt
	zone = "ba.mungard.de."
	name = "vpn"
	addresses = [ var.frankfurt_ip ]
	ttl = 15
}

resource "dns_a_record_set" "azure-client-frankfurt" {
	provider = dns.dns-frankfurt
	zone = "ba.mungard.de."
	name = "azure-client"
	addresses = [ var.dublin_client_ip ]
	ttl = 15
}

resource "dns_a_record_set" "aws-client-frankfurt" {
	provider = dns.dns-frankfurt
	zone = "ba.mungard.de."
	name = "aws-client"
	addresses = [ var.frankfurt_client_ip ]
	ttl = 15
}

provider "dns" {
	alias = "dns-frankfurt-internal"
	update {
		server        = "192.168.200.29"
		key_name      = "fr-vpn-internal.ba.mungard.de."
		// $ tsig-keygen
		key_algorithm = "hmac-sha256"
		key_secret    = "NAKwHBkNE1nI1cfn+Ncw5appqAcDOMIUcGjIxNj7D3w="
	}
}

resource "dns_a_record_set" "www-frankfurt-internal" {
	provider = dns.dns-frankfurt-internal
	zone = "intern.ba.mungard.de."
	name = "www"
	addresses = [ var.frankfurt_www_internal_ip ]
	ttl = 15
}

provider "dns" {
	alias = "dns-dublin"
        update {
                server        = "192.168.200.29"
                key_name      = "db-vpn.ba.mungard.de."
                // $ tsig-keygen
                key_algorithm = "hmac-sha256"
                key_secret    = "KGedaxXcuzNT89pfKBlop1nDW1oPhCgOKyrY+d9aVX4="
        }
}

resource "dns_a_record_set" "vpn-dublin" {
	provider = dns.dns-dublin
        zone = "ba.mungard.de."
        name = "vpn"
        addresses = [ var.dublin_ip ]
        ttl = 15
}

resource "dns_a_record_set" "azure-client-dublin" {
	provider = dns.dns-dublin
        zone = "ba.mungard.de."
        name = "azure-client"
        addresses = [ var.dublin_client_ip ]
        ttl = 15
}

resource "dns_a_record_set" "aws-client-dublin" {
	provider = dns.dns-dublin
        zone = "ba.mungard.de."
        name = "aws-client"
        addresses = [ var.frankfurt_client_ip ]
        ttl = 15
}

provider "dns" {
	alias = "dns-dublin-internal"
        update {
                server        = "192.168.200.29"
                key_name      = "db-vpn-internal.ba.mungard.de."
                // $ tsig-keygen
                key_algorithm = "hmac-sha256"
                key_secret    = "bVfTnWQK5Mgm0YyhKrVSpb8nZ20Rv+KAuPVgMKB6p+I="
        }
}

resource "dns_a_record_set" "www-dublin-internal" {
	provider = dns.dns-dublin-internal
        zone = "intern.ba.mungard.de."
        name = "www"
        addresses = [ var.dublin_www_internal_ip ]
        ttl = 15
}

provider "dns" {
	alias = "dns-nu-internal"
        update {
                server        = "192.168.200.29"
                key_name      = "nu-vpn-internal.ba.mungard.de."
                // $ tsig-keygen
                key_algorithm = "hmac-sha256"
                key_secret    = "o7keZOfPYG3hVb/b2Gp1RwJ5JDAZlD6K5TOwljh/cLs="
        }
}

resource "dns_a_record_set" "www-dublin-nu-internal" {
	provider = dns.dns-nu-internal
        zone = "intern.ba.mungard.de."
        name = "www-azure"
        addresses = [ var.dublin_www_internal_ip ]
        ttl = 15
}

resource "dns_a_record_set" "www-frankfurt-nu-internal" {
        provider = dns.dns-nu-internal
        zone = "intern.ba.mungard.de."
        name = "www-aws"
        addresses = [ var.frankfurt_www_internal_ip ]
        ttl = 15
}

resource "dns_a_record_set" "ovpn-gw-dublin-nu-internal" {
	provider = dns.dns-nu-internal
        zone = "intern.ba.mungard.de."
        name = "vyos-azure-ovpn-gw"
        addresses = [ var.azure_vyos_internal_ip ]
        ttl = 15
}

resource "dns_a_record_set" "ovpn-gw-frankfurt-nu-internal" {
        provider = dns.dns-nu-internal
        zone = "intern.ba.mungard.de."
        name = "vyos-aws-ovpn-gw"
        addresses = [ var.aws_vyos_internal_ip ]
        ttl = 15
}

provider "dns" {
	alias = "dns-nu"
        update {
                server        = "192.168.200.29"
                key_name      = "nu-vpn.ba.mungard.de."
                // $ tsig-keygen
                key_algorithm = "hmac-sha256"
                key_secret    = "Oro6eo3UvHbBZm4KDC8ZdmzAOTIK8EFD61q3j6yyac8="
        }
}

resource "dns_a_record_set" "vpn-nu" {
	provider = dns.dns-nu
        zone = "ba.mungard.de."
        name = "vpn"
        addresses = [ var.kiel_ip ]
        ttl = 15
}

resource "dns_a_record_set" "azure-client-nu" {
	provider = dns.dns-nu
        zone = "ba.mungard.de."
        name = "azure-client"
        addresses = [ var.dublin_client_ip ]
        ttl = 15
}

resource "dns_a_record_set" "aws-client-nu" {
	provider = dns.dns-nu
        zone = "ba.mungard.de."
        name = "aws-client"
        addresses = [ var.frankfurt_client_ip ]
        ttl = 15
}

provider "dns" {
	alias = "dns-all"
        update {
                server        = "192.168.200.29"
                key_name      = "all-vpn.ba.mungard.de."
                // $ tsig-keygen
                key_algorithm = "hmac-sha256"
                key_secret    = "5d7ypaWtJq3I72/lU0t3oYFf+SbbH7HH/yAQh0tSQJo="
        }
}

resource "dns_a_record_set" "all-nu" {
	provider = dns.dns-all
        zone = "ba.mungard.de."
        name = "vpn"
        addresses = [ var.frankfurt_ip, var.kiel_ip, var.dublin_ip ]
        ttl = 15
}

resource "dns_a_record_set" "azure-client-all-nu" {
	provider = dns.dns-all
        zone = "ba.mungard.de."
        name = "azure-client"
        addresses = [ var.dublin_client_ip ]
        ttl = 15
}

resource "dns_a_record_set" "aws-client-all-nu" {
	provider = dns.dns-all
        zone = "ba.mungard.de."
        name = "aws-client"
        addresses = [ var.frankfurt_client_ip ]
        ttl = 15
}
