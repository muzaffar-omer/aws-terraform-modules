
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

# Template to parsed into a shell script that will be 
# executed during web server instance creation, it will be used as AWS user data
data "template_file" "deployment_script" {
  template = "${file("${path.module}/install_nginx_and_certs.tpl")}"

  vars = {
    web_page_file_name = "${var.web_page_file_name}"
    web_page_content   = "${var.web_page_content}"
    domain_name        = "${var.domain_name}"
    email              = "${var.email}"
  }
}

data "template_file" "web_page_deployment_validation" {
  template = "${file("${path.module}/validate_web_page_deployment.tpl")}"

  vars = {
    web_page_name = "${var.web_page_file_name}"
    domain_name   = "${var.domain_name}"
  }
}

# Public key deployed in all created instances, to enable accessing the instances
# using the private key of the key pair
resource "aws_key_pair" "public_key_pair" {
  public_key = "${file("../keys/ex_key.pub")}"
  key_name   = "ExInstancesPublicKey"
}

resource "aws_launch_template" "web_server_launch_template" {
  name          = "Web Server Cluster"
  image_id      = "${data.aws_ami.latest_ubuntu_ami.id}"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.public_key_pair.key_name}"

  # Install nginx
  user_data = "${data.template_file.deployment_script.rendered}"

  # provisioner "local-exec" {
  #   command = "${data.template_file.web_page_deployment_validation.rendered}"
  # }

  vpc_security_group_ids = ["${aws_security_group.web_server_sg.id}"]

  tag_specifications {
      resource_type = "instance"

      tags = {
          Name = "Webserver Instance"
      }
  }
}

resource "aws_autoscaling_group" "web_server_autoscaling_group" {
  name = "Web Server Cluster"

  launch_template {
    id = "${aws_launch_template.web_server_launch_template.id}"
  }

  min_size           = 2
  max_size           = 4
  availability_zones = "${var.availability_zones}"

  vpc_zone_identifier = "${var.subnet_ids}"

  lifecycle {
    create_before_destroy = true
  }
}

# Web server security group
# - Enable incoming HTTP traffic from everywhere
# - Enable incoming SSH traffic from VPC instances only 
# - Enable outgoing HTTP, HTTPS traffic to everywhere
resource "aws_security_group" "web_server_sg" {
  description = "Web server security group"
  vpc_id      = "${var.vpc_id}"

  tags {
    "Name" = "Webserver SG"
  }
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.web_server_sg.id}"

  # Allow incoming HTTP traffic from everywhere

  from_port   = "${var.http_port}"
  to_port     = "${var.http_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "allow_https_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.web_server_sg.id}"

  # Allow incoming HTTPS traffic from everywhere

  from_port   = "${var.https_port}"
  to_port     = "${var.https_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.web_server_sg.id}"

  # Allow incoming SSH traffic from VPC instances only

  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  cidr_blocks = ["${var.bastion_subnets_cidrs}"]
  protocol    = "tcp"
}

resource "aws_security_group_rule" "allow_http_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.web_server_sg.id}"

  # Allow outgoing HTTP traffic to everywhere, this enables
  # installation and update of packages using apt-get
  from_port = "${var.http_port}"

  to_port     = "${var.http_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "allow_https_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.web_server_sg.id}"

  # Allow outgoing HTTPS traffic to everywhere, this enables
  # installation of signing certificates required during installation of apt-get packages
  from_port = "${var.https_port}"

  to_port     = "${var.https_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}
