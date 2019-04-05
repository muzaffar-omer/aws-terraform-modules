resource "aws_lb" "web_server_cluster_lb" {
  name            = "WebServerClusterLB"
  internal        = false
  security_groups = ["${aws_security_group.lb_sg.id}"]
  subnets         = ["${var.subnet_ids}"]

  tags = {
    "VPC" = "${var.vpc_id}"
  }
}

resource "aws_security_group" "lb_sg" {
  description = "Load balancer security group"
  vpc_id      = "${var.vpc_id}"

  tags {
    "Name" = "WebServerLB SG"
    "VPC"  = "${var.vpc_id}"
  }
}

resource "aws_lb_listener" "lb_https_listener" {
  load_balancer_arn = "${aws_lb.web_server_cluster_lb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.tls_certificate_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.lb_https_target_group.arn}"
  }
}

resource "aws_lb_listener" "lb_http_listener" {
  load_balancer_arn = "${aws_lb.web_server_cluster_lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.lb_http_target_group.arn}"
  }
}

resource "aws_security_group_rule" "lb_allow_http_inbound_rule" {
  type              = "ingress"
  security_group_id = "${aws_security_group.lb_sg.id}"

  from_port   = "${var.http_port}"
  to_port     = "${var.http_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "lb_allow_https_inbound_rule" {
  type              = "ingress"
  security_group_id = "${aws_security_group.lb_sg.id}"

  from_port   = "${var.https_port}"
  to_port     = "${var.https_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "lb_allow_http_outbound_rule" {
  type              = "egress"
  security_group_id = "${aws_security_group.lb_sg.id}"

  from_port   = "${var.http_port}"
  to_port     = "${var.http_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "lb_allow_https_outbound_rule" {
  type              = "egress"
  security_group_id = "${aws_security_group.lb_sg.id}"

  from_port   = "${var.https_port}"
  to_port     = "${var.https_port}"
  cidr_blocks = "${var.all_hosts_cidr}"
  protocol    = "tcp"
}


resource "aws_lb_target_group" "lb_http_target_group" {
  name        = "web-servers-http-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"

  tags = {
    Name  = "Webserver LB HTTP Target Group"
    "VPC" = "${var.vpc_id}"
  }
}

resource "aws_lb_target_group" "lb_https_target_group" {
  name        = "web-servers-https-target-group"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"

  tags = {
    Name  = "Webserver LB HTTPS Target Group"
    "VPC" = "${var.vpc_id}"
  }
}
