
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

# Backend server instance
resource "aws_instance" "backend_server" {
  ami           = "${var.ami_id}"
  instance_type = "t2.micro"

  vpc_security_group_ids = ["${aws_security_group.backend_server_sg.id}"]
  subnet_id              = "${var.subnet_id}"

  key_name = "${var.aws_key_name}"

  tags {
    "Name" = "Backend Server"
    "VPC" = "${var.vpc_id}"
  }
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.backend_server_sg.id}"

  # Allow incoming SSH traffic from within the VPC only

  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  cidr_blocks = ["${var.bastion_subnet_cidr}"]
  protocol    = "tcp"

  tags = {
    "VPC" = "${var.vpc_id}"
  }
}

resource "aws_security_group_rule" "allow_http_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.backend_server_sg.id}"

  # Allow outgoing HTTP traffic to everywhere, this enables
  # installation and update of packages using apt-get
  from_port = "${var.http_port}"

  to_port     = "${var.http_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"

  tags = {
    "VPC" = "${var.vpc_id}"
  }
}

resource "aws_security_group_rule" "allow_https_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.backend_server_sg.id}"

  # Allow outgoing HTTPS traffic to everywhere, this enables
  # installation of signing certificates required during installation of apt-get packages
  from_port = "${var.https_port}"

  to_port     = "${var.https_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"

  tags = {
    "VPC" = "${var.vpc_id}"
  }
}
