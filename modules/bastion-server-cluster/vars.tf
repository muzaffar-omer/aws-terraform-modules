variable "vpc_id" {
}

variable "ami_id" {
  description = "ID of the AMI image to be used for creation of autoscaling group instances"
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

variable "private_key_pem" {
  description = "Private key pem content to be transferred into the bastion instance to access other instances"
}

variable "private_key_file_name" {
  description = "Name of the file to store the private key pem"
}

variable "vpc_cidr_block" {
  description = "CIDR of the VPC private IPs, used to allow outgoing SSH traffic from bastion to other instances"
}
