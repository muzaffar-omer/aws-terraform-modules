variable "domain_name" {
  description = "Domain name including the 'www' subdomain, e.g. www.habitat-sd.com"
}

variable "dns_record_type" {
  description = "DNS record type, e.g. A or CNAME or ALIAS"
  default = "CNAME"
}

variable "ttl" {
  default = "60"
}

variable "dns_name_or_ip" {
  description = "DNS name or IP to be configured in the DNS record"
}



