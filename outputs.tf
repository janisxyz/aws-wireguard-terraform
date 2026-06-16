output "wireguard_server_ip" {
  description = "Stable Elastic IP used by the WireGuard endpoint."
  value       = aws_eip.wireguard.public_ip
}

output "instance_id" {
  description = "EC2 instance ID, useful for AWS Systems Manager Session Manager."
  value       = aws_instance.wireguard.id
}

output "client_config_parameter_name" {
  description = "SSM Parameter Store path containing the generated client configuration."
  value       = aws_ssm_parameter.client_config.name
}

output "client_config_command" {
  description = "Run after cloud-init completes to save the WireGuard client configuration locally."
  value       = "aws ssm get-parameter --region ${var.region} --name '${aws_ssm_parameter.client_config.name}' --with-decryption --query 'Parameter.Value' --output text > ~/wireguard-client.conf"
}

output "qr_code_command" {
  description = "Display the generated client configuration as a terminal QR code after installing qrencode."
  value       = "qrencode -t ansiutf8 < ~/wireguard-client.conf"
}

output "ssm_session_command" {
  description = "Open a shell on the server through AWS Systems Manager Session Manager."
  value       = "aws ssm start-session --region ${var.region} --target ${aws_instance.wireguard.id}"
}
