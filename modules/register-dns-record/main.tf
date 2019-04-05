# Select the hosted zone configured for the provided domain name
data "aws_route53_zone" "selected" {
  # Hosted zone names are configured without the www prefix
  # Extract only the top level domain, and subdomain, e.g. habitat-sd.com from www.habitat-sd.com
  name         = "${replace(var.domain_name, "/^[\\w-]+\\.(.*)/", "$1")}" 
}

# Create a DNS record in the hosted zone DNS table
resource "aws_route53_record" "hosted_zone_dns_record" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${var.domain_name}"
  type    = "${var.dns_record_type}"
  ttl     = "${var.ttl}"
  records = ["${var.dns_name_or_ip}"]
}