# Autoscaling group of web servers attached to an application load balancer
# Each web server instance contains and nginx configured with HTTPS
# To serve the static web page
module "web_server_cluster" {
  source = "../modules/web-server-cluster"

  ami_id              = "${data.aws_ami.latest_ubuntu_ami.id}"
  subnet_ids          = ["${aws_subnet.public_sn.*.id}"]
  key_name            = "${aws_key_pair.public_key_pair.key_name}"
  web_page_content    = "${file(var.web_page_file_name)}"
  web_page_file_name  = "${var.web_page_file_name}"
  domain_name         = "${var.domain_name}"
  email               = "${var.email}"
  bastion_server_cidr = ["${aws_subnet.public_sn.*.cidr_block}"]
  vpc_id              = "${aws_vpc.vpc.id}"
  tls_certificate_arn = "${module.issue_certificate.arn}"
  certificate_pem     = "${module.issue_certificate.certificate_pem}"
  certificate_key_pem = "${module.issue_certificate.certificate_key_pem}"
  issuer_pem          = "${module.issue_certificate.issuer_pem}"
  min_no_instances    = 2
  max_no_instances    = 4
}

# Configure the load balancer DNS name in the hosted zone DNS table
module "register_web_server_cluster_dns" {
  source = "../modules/register-dns-record"

  dns_name_or_ip = "${module.web_server_cluster.cluster_lb_dns_name}"
  domain_name    = "${var.domain_name}"
}

# Autoscaling group of bastion instances
module "bastion_server_cluster" {
  source = "../modules/bastion-server-cluster"

  ami_id                = "${data.aws_ami.latest_ubuntu_ami.id}"
  aws_key_name          = "${aws_key_pair.public_key_pair.key_name}"
  subnet_ids            = ["${aws_subnet.public_sn.*.id}"]
  vpc_id                = "${aws_vpc.vpc.id}"
  vpc_cidr_block        = "${aws_vpc.vpc.cidr_block}"
  private_key_pem       = "${file("../keys/${var.ssh_key_file_name}")}"
  private_key_file_name = "${var.ssh_key_file_name}"

  min_no_instances = 2
  max_no_instances = 4
}

# Autoscaling group of backend instances
module "backend_server_cluster" {
  source = "../modules/backend-server-cluster"

  ami_id              = "${data.aws_ami.latest_ubuntu_ami.id}"
  subnet_ids          = ["${aws_subnet.private_sn.*.id}"]
  aws_key_name        = "${aws_key_pair.public_key_pair.key_name}"
  bastion_server_cidr = "${aws_vpc.vpc.cidr_block}"
  vpc_id              = "${aws_vpc.vpc.id}"

  min_no_instances    = 2
  max_no_instances    = 4
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

# Public key deployed in all created instances, to enable accessing the instances
# using the private key of the key pair

data "tls_public_key" "public_key" {
  private_key_pem = "${file("../keys/${var.ssh_key_file_name}")}"
}

# Public key deployed in all created instances, to enable accessing the instances
# using the private key of the key pair
resource "aws_key_pair" "public_key_pair" {
  public_key = "${data.tls_public_key.public_key.public_key_openssh}"
}

# Issue a new Let's Encrypt certificate
module "issue_certificate" {
  source          = "../modules/issue-certificate"
}