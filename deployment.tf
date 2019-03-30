# Use US East (N. Virginia) region as default region
provider "aws" {
  region = "us-east-1"
}

output "backend_private_ip" {
  description = "Backend server public ip"
  value       = "${aws_instance.backend_server.private_ip}"
}


# Look for the latest Ubuntu 18.04 AMI
data "aws_ami" "latest_ubuntu_ami" {
  owners = ["099720109477"] # Canonical (official owner of ubuntu) Owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu*18.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  # Return only the most recent image (returns a single entry)
  most_recent = true
}

data "aws_eip" "web_server_eip" {
  tags = {
    "Name" = "WebServerEIP"
  }
}

variable "ssh_key_file_name" {
  description = "Name of the public key file, contents of this file will be used to create a key_pair in AWS"
  default     = "ex_key"
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

# Use a separate VPC for the exercise
resource "aws_vpc" "ex_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    "Name" = "Exercise VPC"
  }
}

# Public subnet will be used for the Web Server and the Bastion
resource "aws_subnet" "ex_public_sn" {
  vpc_id                  = "${aws_vpc.ex_vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags {
    "Name" = "Public Subnet"
  }
}

# Private subnet will be used for the Backend Server
resource "aws_subnet" "ex_private_sn" {
  vpc_id     = "${aws_vpc.ex_vpc.id}"
  cidr_block = "10.0.2.0/24"

  tags {
    "Name" = "Private Subnet"
  }
}

# Internet Gateway will be attached to the VPC to enable 
# public VPC instances to communicate with the internet
resource "aws_internet_gateway" "ex_igw" {
  vpc_id = "${aws_vpc.ex_vpc.id}"

  tags {
    "Name" = "Exercise VPC Internet Gateway"
  }
}

# Public subnet routing table to all
resource "aws_route_table" "ex_public_subnet_rt" {
  vpc_id = "${aws_vpc.ex_vpc.id}"

  # Forward traffic going to the internet through the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ex_igw.id}"
  }

  tags {
    "Name" = "Public Subnet RT"
  }
}

# Link public subnet with the routing table to forward traffic outgoing
# to the internet through the internet gateway
resource "aws_route_table_association" "ex_public_subnet_rt_assc" {
  route_table_id = "${aws_route_table.ex_public_subnet_rt.id}"
  subnet_id      = "${aws_subnet.ex_public_sn.id}"
}


module "web_server" {
  source = "./modules/web-server"

  ami_id = "${data.aws_ami.latest_ubuntu_ami.id}"
  subnet_id = "${aws_subnet.ex_public_sn.id}"
  key_name = "${aws_key_pair.public_key_pair.key_name}"
  web_page_content = "<body><h1>Awesome Terraform !</h1></body>"
  web_page_file_name = "${var.web_page_file_name}"
  domain_name = "${var.domain_name}"
  email = "${var.email}"
  public_subnet_cidr = "${aws_subnet.ex_public_sn.cidr_block}"
  vpc_id = "${aws_vpc.ex_vpc.id}"
}

# Link the web server to the elastic ip used in DNS
resource "aws_eip_association" "web_server_eip_assc" {
  instance_id = "${module.web_server.instance_id}"
  allocation_id = "${data.aws_eip.web_server_eip.id}"
}

# Public key deployed in all created instances, to enable accessing the instances
# using the private key of the key pair
resource "aws_key_pair" "public_key_pair" {
  public_key = "${file("keys/${var.ssh_key_file_name}.pub")}"
  key_name   = "Ex Instances Public Key"
}

data "local_file" "private_key_rsa" {
  filename = "keys/${var.ssh_key_file_name}"
}


module "bastion_server" {
  source = "./modules/bastion-server"

  ami_id = "${data.aws_ami.latest_ubuntu_ami.id}"
  subnet_id = "${aws_subnet.ex_public_sn.id}"
  aws_key_name = "${aws_key_pair.public_key_pair.key_name}"
  public_subnet_cidr = "${aws_subnet.ex_public_sn.cidr_block}"
  vpc_id = "${aws_vpc.ex_vpc.id}"
  vpc_cidr_block = "${aws_vpc.ex_vpc.cidr_block}"
  private_key_rsa = "${data.local_file.private_key_rsa.content}"
  private_key_file_name = "${var.ssh_key_file_name}"
}

# Backend server security group
# - Enable only SSH traffic incoming from VPC instances only
resource "aws_security_group" "backend_server_sg" {
  description = "Backend server security group"
  vpc_id      = "${aws_vpc.ex_vpc.id}"

  # Allow incoming SSH traffic coming from VPC instances only
  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    cidr_blocks = ["${aws_subnet.ex_public_sn.cidr_block}"]
    protocol    = "tcp"
  }

  tags {
    "Name" = "BackendServer SG"
  }
}

# Backend server instance
resource "aws_instance" "backend_server" {
  ami           = "${data.aws_ami.latest_ubuntu_ami.id}"
  instance_type = "t2.micro"

  vpc_security_group_ids = ["${aws_security_group.backend_server_sg.id}"]
  subnet_id              = "${aws_subnet.ex_private_sn.id}"

  key_name = "${aws_key_pair.public_key_pair.key_name}"

  tags {
    "Name" = "Backend Server"
  }
}
