provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.email}"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = "${acme_registration.reg.account_key_pem}"
  common_name               = "${var.domain_name}"
  subject_alternative_names = ["${random_string.subdomain.result}.habitat-sd.com"]

  dns_challenge {
    provider = "route53"
  }
}

resource "random_string" "subdomain" {
  length = 16
  special = false
  number = false
}