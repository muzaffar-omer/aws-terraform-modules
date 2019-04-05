# Bastion server instance
resource "aws_instance" "bastion_server" {
  ami           = "${var.ami_id}"
  instance_type = "t2.micro"

  vpc_security_group_ids = ["${aws_security_group.bastion_sg.id}"]
  subnet_id              = "${var.subnet_id}"

  key_name = "${var.aws_key_name}"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${var.private_key_pem}"
  }

  # Transfer private key to Bastion
  provisioner "file" {
    content = "${var.private_key_pem}"
    destination = "~/${var.private_key_file_name}"
  }

  # Update the permission of the private key pem file in Bastion server
  provisioner "remote-exec" {
    inline = [
      "chmod 400 ~/${var.private_key_file_name}",
    ]
  }

  tags {
    "Name" = "Bastion Server"
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

# Allow incoming SSH traffic from everywhere
resource "aws_security_group_rule" "allow_ssh_inbound_rule" {
  type              = "ingress"
  security_group_id = "${aws_security_group.bastion_sg.id}"

  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  cidr_blocks = ["${var.all_hosts_cidr}"]
  protocol    = "tcp"
}

resource "aws_security_group_rule" "allow_ssh_outbound_rule" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion_sg.id}"

  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  cidr_blocks = ["${var.vpc_cidr_block}"]
  protocol    = "tcp"
}

# Allow outgoing HTTP traffic to everywhere, this enables
# installation and update of packages using apt-get
resource "aws_security_group_rule" "allow_http_outbound_rule" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion_sg.id}"

  from_port = "${var.http_port}"

  to_port     = "${var.http_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

# Allow outgoing HTTPS traffic to everywhere, this enables
# installation of signing certificates required during installation of apt-get packages
resource "aws_security_group_rule" "allow_https_outbound_rule" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion_sg.id}"

  from_port = "${var.https_port}"

  to_port     = "${var.https_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}
