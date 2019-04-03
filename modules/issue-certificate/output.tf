output "certificate_pem" {
  value = ["${acme_certificate.certificate.*.certificate_pem}", "${data.aws_s3_bucket_object.certificate_s3_object.*.body}"]
  description = "Certificate (public key) issued by Let's Encrypt"
}

output "certificate_key_pem" {
  value = ["${acme_certificate.certificate.*.private_key_pem}", "${data.aws_s3_bucket_object.certificate_key_s3_object.*.body}"]
  description = "Certificate Key (private key) issued by Let's Encrypt"
}

output "issuer_pem" {
  value = ["${acme_certificate.certificate.*.issuer_pem}", "${data.aws_s3_bucket_object.certificate_issuer_s3_object.*.body}"]
  description = "Intermediate Issuer PEM"
}

output "arn" {
  value = ["${aws_iam_server_certificate.lets-encrypt-certificate.*.arn}", "${data.aws_iam_server_certificate.server_certificate.*.arn}"]
  description = "ARN of the registered certificate in IAM"
}
