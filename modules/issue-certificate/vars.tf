variable "email" {
  description = "Email address used to get the certificate from Let's Encrypt"
  default = "muzaffar.omer@gmail.com"
}

variable "domain_name" {
  description = "Domain name used to get the certificate from Let's Encrypt"
  default = "www.habitat-sd.com"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket used to store the certificate artifacts in S3"
  default = "lets-encrypt-tls-certificate"
}

variable "s3_certificate_name" {
  description = "Name of the file to store the certificate (public key) in S3"
  default = "certificate.pem"
}

variable "s3_certificate_key_name" {
  description = "Name of the file used to store certificate key (private key) in S3"
  default = "certificate_key.pem"
}

variable "s3_certificate_issuer_name" {
  description = "Name of the file used to store the certificate of the intermediate issuers"
  default = "issuer_certificate.pem"
}

variable "new_certificate" {
  description = "Whether to generate a new certificate or retrieve an existing certificate from S3 and IAM"
  default = 1
}

