# Use US East (N. Virginia) region as default region
provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "all_availability_zones" {}

# Use a separate VPC for the exercise
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    "Name" = "Exercise VPC - Single Instance"
  }
}

# Public subnet will be used for the Web Server and the Bastion
resource "aws_subnet" "public_sn" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.availability_zone}"

  tags {
    "Name" = "Public Subnet"
    "VPC"  = "${aws_vpc.vpc.id}"
  }
}

# Private subnets will be used for the Backend Servers
resource "aws_subnet" "private_sn" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.availability_zone}"

  tags {
    "Name" = "Private Subnet"
    "VPC"  = "${aws_vpc.vpc.id}"
  }
}

# Internet Gateway will be attached to the VPC to enable 
# public VPC instances to communicate with the internet
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    "Name" = "Exercise VPC Internet Gateway"
    "VPC"  = "${aws_vpc.vpc.id}"
  }
}

# Public subnet routing table to all
resource "aws_route_table" "public_subnet_rt" {
  vpc_id = "${aws_vpc.vpc.id}"

  # Forward traffic going to the internet through the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    "Name" = "Public Subnet RT"
    "VPC"  = "${aws_vpc.vpc.id}"
  }
}

# Link public subnet with the routing table to forward traffic outgoing
# # to the internet through the internet gateway
resource "aws_route_table_association" "public_subnet_rt_assc" {
  route_table_id = "${aws_route_table.public_subnet_rt.id}"
  subnet_id      = "${aws_subnet.public_sn.id}"

  depends_on = ["aws_subnet.public_sn"]
}
