output "wireguard_server_ip" {
  description = "Stable public IP used by the WireGuard endpoint."
  value       = google_compute_address.wireguard.address
}

output "instance_name" {
  description = "Compute Engine instance name."
  value       = google_compute_instance.wireguard.name
}

output "project_id" {
  description = "Google Cloud project containing the deployment."
  value       = var.project_id
}

output "client_config_secret_id" {
  description = "Secret Manager secret containing the generated client profile."
  value       = google_secret_manager_secret.client_config.secret_id
}

output "serial_log_command" {
  description = "Read the VM serial console output for startup troubleshooting."
  value       = "gcloud compute instances get-serial-port-output '${google_compute_instance.wireguard.name}' --project '${var.project_id}' --zone '${var.zone}'"
}
