variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Google Cloud region."
  type        = string
  default     = "europe-west6"
}

variable "zone" {
  description = "Google Cloud zone."
  type        = string
  default     = "europe-west6-a"
}

variable "machine_type" {
  description = "Compute Engine machine type."
  type        = string
  default     = "e2-micro"
}

variable "image" {
  description = "Compute Engine boot image."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "subnet_cidr" {
  description = "IPv4 CIDR for the dedicated subnet."
  type        = string
  default     = "10.20.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "wireguard_port" {
  description = "UDP port exposed for WireGuard."
  type        = number
  default     = 51820

  validation {
    condition     = var.wireguard_port >= 1 && var.wireguard_port <= 65535
    error_message = "wireguard_port must be between 1 and 65535."
  }
}

variable "wireguard_allowed_cidrs" {
  description = "IPv4 CIDRs allowed to reach WireGuard."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.wireguard_allowed_cidrs) > 0 && alltrue([for cidr in var.wireguard_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "wireguard_allowed_cidrs must contain at least one valid IPv4 CIDR."
  }
}

variable "server_address" {
  description = "WireGuard server tunnel address."
  type        = string
  default     = "10.8.0.1/24"
}

variable "client_address" {
  description = "WireGuard client tunnel address."
  type        = string
  default     = "10.8.0.2/32"
}

variable "client_allowed_ips" {
  description = "Networks routed through the WireGuard tunnel."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "client_dns_servers" {
  description = "DNS servers placed in the client profile."
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1"]
}

variable "client_mtu" {
  description = "WireGuard client MTU."
  type        = number
  default     = 1380

  validation {
    condition     = var.client_mtu >= 1280 && var.client_mtu <= 1420
    error_message = "client_mtu must be between 1280 and 1420."
  }
}

variable "client_config_secret_id" {
  description = "Secret Manager secret ID for the generated client profile."
  type        = string
  default     = "wireguard-client-config"
}

variable "boot_disk_size" {
  description = "Boot disk size in GiB."
  type        = number
  default     = 10
}

variable "labels" {
  description = "Labels applied to the Compute Engine instance."
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "wireguard"
  }
}
