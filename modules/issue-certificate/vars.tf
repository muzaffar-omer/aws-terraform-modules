variable "email" {
  default = "muzaffar.omer@gmail.com"
}

variable "domain_name" {
  default = "www.habitat-sd.com"
}

variable "s3_bucket_name" {
  default = "lets-encrypt-tls-certificate"
}

variable "s3_certificate_name" {
  default = "certificate.pem"
}

variable "s3_certificate_key_name" {
  default = "certificate_key.pem"
}

variable "s3_certificate_issuer_name" {
  default = "issuer_certificate.pem"
}

variable "new_certificate" {
  default = 0
}

