output "wireguard_server_ip" {
  value = aws_instance.wireguard.public_ip
}

output "instructions" {
  value = "Retrieve client config from SSM Parameter Store securely."
}