
resource "aws_launch_template" "backend_server_launch_template" {
  name          = "BackendServerCluster"
  image_id      = "${var.ami_id}"
  instance_type = "t2.micro"
  key_name      = "${var.aws_key_name}"

  vpc_security_group_ids = ["${aws_security_group.backend_server_sg.id}"]

  tag_specifications {
      resource_type = "instance"

      tags = {
          "Name" = "Backend Server Instance"
          "VPC" = "${var.vpc_id}"
      }
  }
}

resource "aws_autoscaling_group" "backend_server_autoscaling_group" {
  name = "BackendServerCluster"

  launch_template {
    id = "${aws_launch_template.backend_server_launch_template.id}"
  }

  min_size           = "${var.min_no_instances}"
  max_size           = "${var.max_no_instances}"
  vpc_zone_identifier = ["${var.subnet_ids}"]

  lifecycle {
    create_before_destroy = true
  }

  tags {
    key = "VPC"
    value = "${var.vpc_id}"
    propagate_at_launch = true
  }
}

# Backend server security group
# - Enable only SSH traffic incoming from VPC instances only
resource "aws_security_group" "backend_server_sg" {
  description = "Backend server security group"
  vpc_id      = "${var.vpc_id}"

  tags {
    "Name" = "BackendServer SG"
    "VPC" = "${var.vpc_id}"
  }
}

# Allow incoming traffic from bastion server only
resource "aws_security_group_rule" "allow_ssh_inbound_rule" {
  type              = "ingress"
  security_group_id = "${aws_security_group.backend_server_sg.id}"

  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  cidr_blocks = ["${var.bastion_server_cidr}"]
  protocol    = "tcp"
}