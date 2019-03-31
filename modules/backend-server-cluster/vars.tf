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

variable "min_no_instances" {
  
}

variable "max_no_instances" {
  
}


variable "bastion_subnet_cidr" {
  
}
