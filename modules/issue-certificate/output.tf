output "certificate_pem" {
  value = "${acme_certificate.certificate.certificate_pem}"
  description = "Certificate (public key) issued by Let's Encrypt"
}

output "certificate_key_pem" {
  value = "${acme_certificate.certificate.private_key_pem}"
  description = "Certificate Key (private key) issued by Let's Encrypt"
}

output "issuer_pem" {
  value = "${acme_certificate.certificate.issuer_pem}"
  description = "Intermediate Issuer PEM"
}


