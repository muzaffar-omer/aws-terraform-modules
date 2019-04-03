provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

#######################################################################
# Creating new certificate
#######################################################################
resource "tls_private_key" "private_key" {
  count = "${var.new_certificate}"
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  count = "${var.new_certificate}"
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.email}"
}

resource "acme_certificate" "certificate" {
  count = "${var.new_certificate}"
  account_key_pem           = "${acme_registration.reg.account_key_pem}"
  common_name               = "${var.domain_name}"
  subject_alternative_names = ["${random_string.subdomain.result}.habitat-sd.com"]

  dns_challenge {
    provider = "route53"
  }
}

resource "aws_iam_server_certificate" "lets-encrypt-certificate" {
  count = "${var.new_certificate}"
  name  = "lets-encrypt-certificate"

  #certificate_chain = "${format("%s%s", acme_certificate.certificate.certificate_pem, acme_certificate.certificate.issuer_pem)}"
  certificate_body = "${acme_certificate.certificate.certificate_pem}"
  private_key      = "${acme_certificate.certificate.private_key_pem}"
}

resource "random_string" "subdomain" {
  count = "${var.new_certificate}"
  length  = 16
  special = false
  number  = false
}

resource "aws_s3_bucket" "certificate_bucket" {
  count = "${var.new_certificate}"
  bucket = "${var.s3_bucket_name}"
  acl    = "private"
  force_destroy = true

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_object" "certificate_s3_object" {
  count = "${var.new_certificate}"
  bucket  = "${var.s3_bucket_name}"
  key     = "${var.s3_certificate_name}"
  content = "${acme_certificate.certificate.certificate_pem}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "certificate_key_s3_object" {
  count = "${var.new_certificate}"
  bucket  = "${var.s3_bucket_name}"
  key     = "${var.s3_certificate_key_name}"
  content = "${acme_certificate.certificate.private_key_pem}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "certificate_issuer_s3_object" {
  count = "${var.new_certificate}"
  bucket  = "${var.s3_bucket_name}"
  key     = "${var.s3_certificate_issuer_name}"
  content = "${acme_certificate.certificate.issuer_pem}"
  content_type = "text/plain"
}

######################################################################
# Retrieving existing certificate from S3 and IAM
#######################################################################
data "aws_iam_server_certificate" "server_certificate" {
  count = "${1 - var.new_certificate}"
  name   = "lets-encrypt-certificate"
  latest = true
}

data "aws_s3_bucket_object" "certificate_s3_object" {
  count = "${1 - var.new_certificate}"
  bucket = "${var.s3_bucket_name}"
  key    = "${var.s3_certificate_name}"
}

data "aws_s3_bucket_object" "certificate_key_s3_object" {
  count = "${1 - var.new_certificate}"
  bucket = "${var.s3_bucket_name}"
  key    = "${var.s3_certificate_key_name}"
}

data "aws_s3_bucket_object" "certificate_issuer_s3_object" {
  count = "${1 - var.new_certificate}"
  bucket = "${var.s3_bucket_name}"
  key    = "${var.s3_certificate_issuer_name}"
}