
variable "ssh_key_file_name" {
  description = "Name of the public key file, contents of this file will be used to create a key_pair in AWS"
  default     = "private.pem"
}

variable "http_port" {
  description = "Default HTTP port"
  default     = "80"
}

variable "ssh_port" {
  description = "Default SSH port"
  default     = "22"
}

variable "https_port" {
  description = "Default HTTPS port"
  default = "443"
}

variable "all_hosts_cidr" {
  description = "CIDR to allow traffic for all hosts"
  default     = ["0.0.0.0/0"]
}

variable "web_page_file_name" {
  description = "Name of the web page file which will be deployed to the web server instance"
  default     = "index.html"
}

variable "domain_name" {
  description = "Domain name used for deployment of the certificates"
  default = "www.habitat-sd.com"
}

variable "email" {
  description = "Email address used during deployment of certificates"
  default = "muzaffar.omer@gmail.com"
}
variable "availability_zone" {
  default = "us-east-1a"
}
