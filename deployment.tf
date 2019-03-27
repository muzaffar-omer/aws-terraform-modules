# Use US East (N. Virginia) region as default
provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}

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

resource "aws_route_table" "ex_public_subnet_rt" {
  vpc_id = "${aws_vpc.ex_vpc.id}"

  # Traffic going to the internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ex_igw.id}"
  }

  tags {
    "Name" = "Public Subnet RT"
  }
}

resource "aws_route_table_association" "ex_public_subnet_rt_assc" {
  route_table_id = "${aws_route_table.ex_public_subnet_rt.id}"
  subnet_id      = "${aws_subnet.ex_public_sn.id}"
}

# Look for the latest Ubuntu 18.04 AMI
data "aws_ami" "latest_ubuntu_ami" {
  owners = ["099720109477"]

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

variable "web_page" {
  description = "The web page with the static content to be served by the web server"
  default     = "index.html"
}

resource "aws_s3_bucket" "web_page_s3_bucket" {
  bucket = "${var.web_page_bucket_name}"
  region = "${data.aws_region.current.name}"

  tags {
    "Name" = "Static Web Page Bucket"
  }
}

resource "aws_s3_bucket_object" "web_page_s3_object" {
  bucket = "${aws_s3_bucket.web_page_s3_bucket.id}"
  source = "${var.web_page}"
  key    = "${var.web_page}"

  tags {
    "Name" = "The static page to be served by nginx"
  }
}

variable "web_page_bucket_name" {
  default = "pix4d.ex.static-web-page-bucket"
}


data "aws_s3_bucket_object" "web_page_content" {
  bucket = "${var.web_page_bucket_name}"
  key    = "${var.web_page}"

  depends_on = ["aws_s3_bucket_object.web_page_s3_object"]
}

# Web server instance
resource "aws_instance" "web_server" {
  ami           = "${data.aws_ami.latest_ubuntu_ami.id}"
  instance_type = "t2.micro"

  vpc_security_group_ids = ["${aws_security_group.ws_sg.id}"]
  subnet_id              = "${aws_subnet.ex_public_sn.id}"

  key_name = "${aws_key_pair.public_key_pair.key_name}"

  # Install nginx
  user_data = <<-EOF
    sudo apt-get update -y
    sudo apt-get install -y nginx
  EOF

  provisioner "file" {
    content     = "${data.aws_s3_bucket_object.web_page_content.body}"
    destination = "/var/www/html/${var.web_page}"
  }

  # Test that the static content is deployed properly
  provisioner "local-exec" {
    command = "wget -O/dev/null -q http://${aws_instance.web_server.public_ip}/${var.web_page} && echo 'Web page is deployed properly !'"
  }
  
  depends_on = ["aws_s3_bucket.web_page_s3_bucket"]

  tags {
    "Name" = "Nginx Web Server"
  }
}

# Contains the Public IP of the Web Server
output "ws_public_ip" {
  description = "Public IP of the web server"
  value       = "${aws_instance.web_server.public_ip}"
}

variable "ws_http_port" {
  description = "Default Web Server HTTP port"
  default     = "80"
}

variable "ws_ssh_port" {
  description = "Default Web Server SSH port"
  default     = "22"
}

variable "ws_cidr" {
  description = "CIDR to receive traffic from all hosts"
  default     = ["0.0.0.0/0"]
}

resource "aws_security_group" "ws_sg" {
  description = "Web server security group"
  vpc_id      = "${aws_vpc.ex_vpc.id}"

  # Allow incoming traffic in port 80
  ingress {
    from_port   = "${var.ws_http_port}"
    to_port     = "${var.ws_http_port}"
    cidr_blocks = "${var.ws_cidr}"
    protocol    = "tcp"
  }

  # Allow incoming traffic in port 22
  ingress {
    from_port   = "${var.ws_ssh_port}"
    to_port     = "${var.ws_ssh_port}"
    cidr_blocks = ["${aws_subnet.ex_public_sn.cidr_block}"]
    protocol    = "tcp"
  }

  # Allow outgoing traffic in port 80
  egress {
    from_port   = "${var.ws_http_port}"
    to_port     = "${var.ws_http_port}"
    cidr_blocks = "${var.ws_cidr}"
    protocol    = "tcp"
  }

  tags {
    "Name" = "Webserver SG"
  }
}

######################## Exercise 4 ###################################

resource "aws_key_pair" "public_key_pair" {
  public_key = "${file("keys/${var.ssh_key}.pub")}"
  key_name   = "Ex Instances Public Key"
}

output "bastion_public_ip" {
  description = "Bastion server public ip"
  value       = "${aws_instance.bastion_server.public_ip}"
}

resource "aws_security_group" "bastion_sg" {
  description = "Bastion server security group"
  vpc_id      = "${aws_vpc.ex_vpc.id}"

  # Allow incoming SSH traffic from everywhere
  ingress {
    from_port   = "${var.ws_ssh_port}"
    to_port     = "${var.ws_ssh_port}"
    cidr_blocks = "${var.ws_cidr}"
    protocol    = "tcp"
  }

  # Allow outgoing SSH traffic toward any instances in the VPC
  egress {
    from_port   = "${var.ws_ssh_port}"
    to_port     = "${var.ws_ssh_port}"
    cidr_blocks = ["${aws_vpc.ex_vpc.cidr_block}"]
    protocol    = "tcp"
  }

  tags {
    "Name" = "BastionServer SG"
  }
}

variable "ssh_key" {
  description = "Name of the public key to be generated in local host and deployed to the instances"
  default     = "ex_key"
}

resource "aws_instance" "bastion_server" {
  ami           = "${data.aws_ami.latest_ubuntu_ami.id}"
  instance_type = "t2.micro"

  vpc_security_group_ids = ["${aws_security_group.bastion_sg.id}"]
  subnet_id              = "${aws_subnet.ex_public_sn.id}"

  key_name = "${aws_key_pair.public_key_pair.key_name}"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("keys/${var.ssh_key}")}"
  }

  # Transfer private key to Bastion
  provisioner "file" {
    source      = "keys/${var.ssh_key}"
    destination = "~/${var.ssh_key}"
  }

  # Try connecting to the backend server from bastion server
  provisioner "remote-exec" {
    inline = [
      "chmod 400 ~/${var.ssh_key}",
    ]
  }

  tags {
    "Name" = "Bastion Server"
  }
}

output "backend_private_ip" {
  description = "Backend server public ip"
  value       = "${aws_instance.backend_server.private_ip}"
}

resource "aws_security_group" "backend_server_sg" {
  description = "Backend server security group"
  vpc_id      = "${aws_vpc.ex_vpc.id}"

  # Allow incoming traffic in port 22
  ingress {
    from_port   = "${var.ws_ssh_port}"
    to_port     = "${var.ws_ssh_port}"
    cidr_blocks = ["${aws_subnet.ex_public_sn.cidr_block}"]
    protocol    = "tcp"
  }

  tags {
    "Name" = "BackendServer SG"
  }
}

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
