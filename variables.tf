variable "region" {
  description = "AWS region in which to deploy the VPN server."
  type        = string
  default     = "eu-central-2"
}

variable "instance_type" {
  description = "EC2 instance type for the WireGuard server."
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the dedicated VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "subnet_cidr" {
  description = "IPv4 CIDR for the public subnet."
  type        = string
  default     = "10.0.1.0/24"

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
  description = "IPv4 CIDRs allowed to reach the WireGuard UDP port. Mobile clients generally require 0.0.0.0/0."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.wireguard_allowed_cidrs) > 0 && alltrue([for cidr in var.wireguard_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "wireguard_allowed_cidrs must contain at least one valid IPv4 CIDR."
  }
}

variable "server_address" {
  description = "WireGuard server tunnel address, including prefix length."
  type        = string
  default     = "10.8.0.1/24"

  validation {
    condition     = can(cidrnetmask(var.server_address))
    error_message = "server_address must be a valid IPv4 interface CIDR."
  }
}

variable "client_address" {
  description = "WireGuard client tunnel address, including prefix length."
  type        = string
  default     = "10.8.0.2/32"

  validation {
    condition     = can(cidrnetmask(var.client_address))
    error_message = "client_address must be a valid IPv4 interface CIDR."
  }
}

variable "client_allowed_ips" {
  description = "Networks routed through the WireGuard tunnel by the client."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.client_allowed_ips) > 0 && alltrue([for cidr in var.client_allowed_ips : can(cidrnetmask(cidr))])
    error_message = "client_allowed_ips must contain at least one valid IPv4 CIDR."
  }
}

variable "client_dns_servers" {
  description = "DNS servers included in the generated client configuration."
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1"]

  validation {
    condition     = length(var.client_dns_servers) > 0
    error_message = "client_dns_servers must contain at least one DNS server."
  }
}

variable "client_mtu" {
  description = "WireGuard client MTU. 1380 is a conservative value for mobile networks."
  type        = number
  default     = 1380

  validation {
    condition     = var.client_mtu >= 1280 && var.client_mtu <= 1420
    error_message = "client_mtu must be between 1280 and 1420."
  }
}

variable "client_config_parameter_name" {
  description = "SSM Parameter Store path used for the generated WireGuard client configuration."
  type        = string
  default     = "/wireguard/client-config"

  validation {
    condition     = startswith(var.client_config_parameter_name, "/") && length(var.client_config_parameter_name) > 1
    error_message = "client_config_parameter_name must be an absolute SSM parameter path such as /wireguard/client-config."
  }
}

variable "root_volume_size" {
  description = "Encrypted gp3 root volume size in GiB."
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "root_volume_size must be at least 8 GiB."
  }
}

variable "tags" {
  description = "Tags applied to all taggable AWS resources."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "aws-wireguard-terraform"
  }
}
