variable "vpc_id" {
}


variable "ami_id" {
  description = "ID of the AMI image to be used for creation of the instance"
}

variable "subnet_id" {
  description = "ID of the subnet where the instance will be deployed"
}

variable "aws_key_name" {
  description = "Name of the public key in AWS"
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

variable "all_hosts_cidr" {
  default = ["0.0.0.0/0"]
}

variable "bastion_server_cidr" {
  description = "Bastion server IP CIDR"
}


