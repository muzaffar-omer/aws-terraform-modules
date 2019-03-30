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
