output "instance_id" {
  value = "${aws_instance.web_server.id}"
}

output "public_ip" {
  value = "${aws_instance.web_server.public_ip}"
}

output "private_ip" {
  value = "${aws_instance.web_server.private_ip}"
}

output "public_dns_name" {
  value = "${aws_instance.web_server.public_dns}"
}

