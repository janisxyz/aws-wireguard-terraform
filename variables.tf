variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH (restrict for security)"
  type        = string
  default     = "0.0.0.0/0"  # Change to your IP
}

variable "wireguard_port" {
  description = "WireGuard UDP port"
  type        = number
  default     = 51820
}