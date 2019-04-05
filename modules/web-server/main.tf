# Template parsed into a shell script that will be 
# executed during web server instance creation, it will be used as AWS user data
# output script will perform the below actions:
# - Installs nginx
# - Create the web page file in the nginx web-root directory
# - Create certificate artifacts to be used by nginx for HTTPS
data "template_file" "deployment_script" {
  template = "${file("${path.module}/templates/install_nginx_and_certs.tpl")}"

  vars = {
    web_page_file_name  = "${var.web_page_file_name}"
    web_page_content    = "${var.web_page_content}"
    domain_name         = "${var.domain_name}"
    email               = "${var.email}"
    nginx_config        = "${file("${path.module}/templates/nginx.config")}"
    certificate_pem     = "${var.certificate_pem}"
    certificate_key_pem = "${var.certificate_key_pem}"
    issuer_pem          = "${var.issuer_pem}"
  }
}

# data "template_file" "web_page_deployment_validation" {
#   template = "${file("${path.module}/templates/validate_web_page_deployment.tpl")}"

#   vars = {
#     web_page_name = "${var.web_page_file_name}"
#     domain_name   = "${var.domain_name}"
#   }
# }

# Web server instance
resource "aws_instance" "web_server" {
  ami           = "${var.ami_id}"
  instance_type = "t2.micro"

  vpc_security_group_ids = ["${aws_security_group.web_server_sg.id}"]
  subnet_id              = "${var.subnet_id}"

  key_name = "${var.key_name}"

  # Install nginx
  user_data = "${data.template_file.deployment_script.rendered}"

  # provisioner "local-exec" {
  #   command = "${data.template_file.web_page_deployment_validation.rendered}"
  # }

  tags {
    "Name" = "Nginx Web Server"
    "VPC"  = "${var.vpc_id}"
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
    "VPC"  = "${var.vpc_id}"
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

  # Allow incoming SSH traffic from Bastion server only

  from_port = "${var.ssh_port}"
  to_port   = "${var.ssh_port}"
  cidr_blocks = ["${var.bastion_server_cidr}"]
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
