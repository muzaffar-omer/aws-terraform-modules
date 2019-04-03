data "aws_route53_zone" "selected" {
  # Extract only the top level domain, and subdomain, e.g. habitat-sd.com from www.habitat-sd.com
  name         = "${replace(var.domain_name, "/^[\\w-]+\\.(.*)/", "$1")}" 
}

resource "aws_route53_record" "hosted_zone_dns_record" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${var.domain_name}"
  type    = "${var.dns_record_type}"
  ttl     = "${var.ttl}"
  records = ["${var.dns_name_or_ip}"]
}