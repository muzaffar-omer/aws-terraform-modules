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
    Name = "WSStaticIP"
  }
}

data "tls_public_key" "public_key" {
  private_key_pem = "${file("../keys/${var.ssh_key_file_name}")}"
}

# Link the web server to the elastic ip used in DNS
resource "aws_eip_association" "web_server_eip_assc" {
  instance_id   = "${module.web_server.instance_id}"
  allocation_id = "${data.aws_eip.web_server_eip.id}"
}

# Public key deployed in all created instances, to enable accessing the instances
# using the private key of the key pair
resource "aws_key_pair" "public_key_pair" {
  public_key = "${data.tls_public_key.public_key.public_key_openssh}"
  key_name   = "ExInstancesPublicKey"
}

module "issue_certificate" {
  source = "../modules/issue-certificate"
}

module "web_server" {
  source = "../modules/web-server"

  ami_id              = "${data.aws_ami.latest_ubuntu_ami.id}"
  subnet_id           = "${aws_subnet.public_sn.id}"
  key_name            = "${aws_key_pair.public_key_pair.key_name}"
  web_page_content    = "${file(var.web_page_file_name)}"
  web_page_file_name  = "${var.web_page_file_name}"
  domain_name         = "${var.domain_name}"
  email               = "${var.email}"
  bastion_server_cidr = "${module.bastion_server.private_ip}/32"
  vpc_id              = "${aws_vpc.vpc.id}"
  certificate_pem     = "${module.issue_certificate.certificate_pem}"
  certificate_key_pem = "${module.issue_certificate.certificate_key_pem}"
  issuer_pem          = "${module.issue_certificate.issuer_pem}"
}

module "bastion_server" {
  source = "../modules/bastion-server"

  ami_id                = "${data.aws_ami.latest_ubuntu_ami.id}"
  subnet_id             = "${aws_subnet.public_sn.id}"
  aws_key_name          = "${aws_key_pair.public_key_pair.key_name}"
  vpc_id                = "${aws_vpc.vpc.id}"
  vpc_cidr_block        = "${aws_vpc.vpc.cidr_block}"
  private_key_pem       = "${file("../keys/${var.ssh_key_file_name}")}"
  private_key_file_name = "${var.ssh_key_file_name}"
}

module "backend_server" {
  source = "../modules/backend-server"

  ami_id              = "${data.aws_ami.latest_ubuntu_ami.id}"
  subnet_id           = "${aws_subnet.private_sn.id}"
  aws_key_name        = "${aws_key_pair.public_key_pair.key_name}"
  bastion_server_cidr = "${module.bastion_server.private_ip}/32"
  vpc_id              = "${aws_vpc.vpc.id}"
}
