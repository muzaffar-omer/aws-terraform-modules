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

  # Return only the most recent image
  most_recent = true
}

# Web server instance
resource "aws_instance" "web_server" {
  ami = "${data.aws_ami.latest_ubuntu_ami.id}"
  instance_type = "t2.micro"
}

# Contains the Public IP of the Web Server
output "public_ip" {
  value = "${aws_instance.web_server.public_ip}"
}
