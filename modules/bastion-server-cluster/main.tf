data "template_file" "private_key_deployment_script" {
  template = "${file("${path.module}/deploy_private_key.tpl")}"

  vars = {
    private_key_rsa = "${var.private_key_rsa}"
    private_key_file_name   = "${var.private_key_file_name}"
  }
}

resource "aws_launch_template" "bastion_server_launch_template" {
  name          = "BastionServerCluster"
  image_id      = "${var.ami_id}"
  instance_type = "t2.micro"
  key_name      = "${var.aws_key_name}"

  # Install nginx
  user_data = "${base64encode(data.template_file.private_key_deployment_script.rendered)}"
  vpc_security_group_ids = ["${aws_security_group.bastion_sg.id}"]

  tag_specifications {
      resource_type = "instance"

      tags = {
          "Name" = "Bastion Server Instance"
          "VPC" = "${var.vpc_id}"
      }
  }
}

resource "aws_autoscaling_group" "bastion_server_autoscaling_group" {
  name = "BastionServerCluster"

  launch_template {
    id = "${aws_launch_template.bastion_server_launch_template.id}"
  }

  min_size           = "${var.min_no_instances}"
  max_size           = "${var.max_no_instances}"
  vpc_zone_identifier = ["${var.subnet_ids}"]

  lifecycle {
    create_before_destroy = true
  }

  tags {
    "VPC" = "${var.vpc_id}"
  }
}

# Bastion server security group
# - Enable SSH incoming from anywhere
# - Enable SSH outgoing toward instances of the VPC only
resource "aws_security_group" "bastion_sg" {
  description = "Bastion server security group"
  vpc_id      = "${var.vpc_id}"

  tags {
    "Name" = "BastionServer SG"
    "VPC" = "${var.vpc_id}"
  }
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.bastion_sg.id}"

  # Allow incoming SSH traffic from everywhere

  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  cidr_blocks = ["${var.all_hosts_cidr}"]
  protocol    = "tcp"
}

resource "aws_security_group_rule" "allow_ssh_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion_sg.id}"

  # Allow incoming SSH traffic from everywhere

  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  cidr_blocks = ["${var.vpc_cidr_block}"]
  protocol    = "tcp"
}

resource "aws_security_group_rule" "allow_http_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion_sg.id}"

  # Allow outgoing HTTP traffic to everywhere, this enables
  # installation and update of packages using apt-get
  from_port = "${var.http_port}"

  to_port     = "${var.http_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "allow_https_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion_sg.id}"

  # Allow outgoing HTTPS traffic to everywhere, this enables
  # installation of signing certificates required during installation of apt-get packages
  from_port = "${var.https_port}"

  to_port     = "${var.https_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

