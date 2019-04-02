
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
  type              = "ingress"
  security_group_id = "${aws_security_group.backend_server_sg.id}"

  # Allow incoming SSH traffic from within the VPC only

  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  cidr_blocks = ["${var.bastion_server_cidr}"]
  protocol    = "tcp"
}
