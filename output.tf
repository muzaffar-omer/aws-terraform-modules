
output "backend_private_ip" {
  description = "Backend server public ip"
  value       = "${aws_instance.backend_server.private_ip}"
}
