# Template to parsed into a shell script that will be 
# executed during web server instance creation, it will be used as AWS user data
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

data "template_file" "web_page_deployment_validation" {
  template = "${file("${path.module}/templates/validate_web_page_deployment.tpl")}"

  vars = {
    web_page_name = "${var.web_page_file_name}"
    domain_name   = "${var.domain_name}"
  }
}

resource "aws_launch_template" "web_server_launch_template" {
  name          = "WebserverCluster"
  image_id      = "${var.ami_id}"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"

  # Install nginx
  user_data = "${base64encode(data.template_file.deployment_script.rendered)}"

  vpc_security_group_ids = ["${aws_security_group.web_server_sg.id}"]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name  = "Webserver Instance"
      "VPC" = "${var.vpc_id}"
    }
  }
}

resource "aws_autoscaling_group" "web_server_autoscaling_group" {
  name = "WebserverCluster"

  launch_template {
    id = "${aws_launch_template.web_server_launch_template.id}"
  }

  min_size            = "${var.min_no_instances}"
  max_size            = "${var.max_no_instances}"
  vpc_zone_identifier = ["${var.subnet_ids}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "VPC"
    value               = "${var.vpc_id}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg_http_attachment" {
  autoscaling_group_name = "${aws_autoscaling_group.web_server_autoscaling_group.id}"
  alb_target_group_arn   = "${aws_lb_target_group.lb_http_target_group.arn}"
}

resource "aws_autoscaling_attachment" "asg_https_attachment" {
  autoscaling_group_name = "${aws_autoscaling_group.web_server_autoscaling_group.id}"
  alb_target_group_arn   = "${aws_lb_target_group.lb_https_target_group.arn}"
}

# resource "null_resource" "validate_web_page_deployment" {
#   provisioner "local-exec" {
#     command = "${data.template_file.web_page_deployment_validation.rendered}"
#   }

#   depends_on = ["aws_autoscaling_group.web_server_autoscaling_group"]
# }

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


resource "aws_security_group_rule" "web_server_allow_ssh_inbound_rule" {
  type              = "ingress"
  security_group_id = "${aws_security_group.web_server_sg.id}"

  # Allow incoming SSH traffic from VPC instances only

  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  cidr_blocks = ["${var.bastion_server_cidr}"]
  protocol    = "tcp"
}

resource "aws_security_group_rule" "web_server_allow_http_inbound_rule" {
  type              = "ingress"
  security_group_id = "${aws_security_group.web_server_sg.id}"

  # Allow outgoing HTTP traffic to everywhere, this enables
  # installation and update of packages using apt-get
  from_port = "${var.http_port}"

  to_port     = "${var.http_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "web_server_allow_https_inbound_rule" {
  type              = "ingress"
  security_group_id = "${aws_security_group.web_server_sg.id}"

  # Allow outgoing HTTPS traffic to everywhere, this enables
  # installation of signing certificates required during installation of apt-get packages
  from_port = "${var.https_port}"

  to_port     = "${var.https_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "web_server_allow_http_outbound_rule" {
  type              = "egress"
  security_group_id = "${aws_security_group.web_server_sg.id}"

  # Allow outgoing HTTP traffic to everywhere, this enables
  # installation and update of packages using apt-get
  from_port = "${var.http_port}"

  to_port     = "${var.http_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

# Allow outgoing HTTPS traffic to everywhere, this enables
# installation of signing certificates required during installation of apt-get packages
resource "aws_security_group_rule" "web_server_allow_https_outbound_rule" {
  type              = "egress"
  security_group_id = "${aws_security_group.web_server_sg.id}"

  from_port = "${var.https_port}"

  to_port     = "${var.https_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}
