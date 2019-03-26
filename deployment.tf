# Use US East (N. Virginia) region as default
provider "aws" {
  region = "us-east-1"
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

# Web server instance
resource "aws_instance" "web_server" {
  ami           = "${data.aws_ami.latest_ubuntu_ami.id}"
  instance_type = "t2.micro"

  vpc_security_group_ids = ["${aws_security_group.ws_sg.id}"]

  key_name = "WSKeyPair"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("keys/WSKeyPair.pem")}"
  }

  # Install nginx using the default ubuntu repository, but a better approach
  # could be to add nginx repository to the apt sources list, and install the latest
  # nginx version. But this requires opening port 443 (HTTPS) in the instance
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
    ]
  }

  # Transfer the web page from the local machine to the remote instance in
  # the directory /var/tmp/ to be moved late to nginx default html directory
  # /var/www/html
  provisioner "file" {
    source      = "${var.web_page}"
    destination = "/var/tmp/${var.web_page}"
  }

  # Move the web page file from /var/tmp/ directory into /var/www/html 
  # directory. As /var/www/html directory requires root permission
  provisioner "remote-exec" {
    inline = [
      "sudo mv /var/tmp/${var.web_page} /var/www/html/${var.web_page}",
    ]
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
    cidr_blocks = "${var.ws_cidr}"
    protocol    = "tcp"
  }

  # Allow outgoing traffic in port 80
  egress {
    from_port   = "${var.ws_http_port}"
    to_port     = "${var.ws_http_port}"
    cidr_blocks = "${var.ws_cidr}"
    protocol    = "tcp"
  }
}
