output "cluster_lb_dns_name" {
  value = "${aws_lb.web_server_cluster_lb.dns_name}"
}
