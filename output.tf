
output "backend_private_ip" {
  description = "Backend server public ip"
  value       = "${module.backend_server.private_ip}"
}


output "bastion_server_private_ip" {
  value = "${module.bastion_server.private_ip}"
}

output "bastion_server_public_ip" {
  value = "${module.bastion_server.public_ip}"
}

output "web_server_private_ip" {
  value = "${module.web_server.private_ip}"
}

output "web_server_public_ip" {
  value = "${module.web_server.public_ip}"
}
