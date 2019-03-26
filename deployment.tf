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

# Web server instance
resource "aws_instance" "web_server" {
  ami           = "${data.aws_ami.latest_ubuntu_ami.id}"
  instance_type = "t2.micro"

  vpc_security_group_ids = ["${aws_security_group.ws_sg.id}"]

  key_name = "WSKeyPair"

  connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("keys/WSKeyPair.pem")}"
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
}
