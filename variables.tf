variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "allowed_ssh_cidr" {
  default = "0.0.0.0/0"  # Change to your IP for security
}