variable "vpc_id" {
  description = "Used in the web server security group"
}

variable "ami_id" {
  description = "ID of the AMI image to be used for creation of autoscaling group web server instances"
}

variable "subnet_ids" {
  description = "IDs of the subnets where to deploy the auto scaling group instances"
  type = "list"
}

variable "key_name" {
  description = "Name of the public key in AWS"
}

variable "web_page_content" {
 description = "Contents of the static web page to deploy in the web server" 
}

variable "web_page_file_name" {
  description = "Name of the web page to use inside the web server root directory"
}

variable "domain_name" {
  description = "Domain name used in generation of certificates"
  default = "www.habitat-sd.com"
}

variable "email" {
  description = "Email address used in generation of certificates"
  default = "muzaffar.omer@gmail.com"
}

variable "http_port" {
  default = "80"
}

variable "https_port" {
  default = "443"
}

variable "ssh_port" {
  default = "22"
}

variable "bastion_server_cidr" {
  description = "CIDR block of the public subnet of the bastion server, this is used to allow SSH traffic coming from bastion server"
  type = "list"
}

variable "all_hosts_cidr" {
  default = ["0.0.0.0/0"]
}


variable "certificate_pem" {
  
}

variable "certificate_key_pem" {
  
}

variable "issuer_pem" {
  
}

variable "min_no_instances" {
  
}

variable "max_no_instances" {
  
}

variable "tls_certificate_arn" {
  
}
