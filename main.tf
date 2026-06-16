terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

data "aws_partition" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "wireguard-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "wireguard-public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "wireguard-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "wireguard-public-routes"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "wireguard" {
  name_prefix            = "wireguard-"
  description            = "WireGuard VPN ingress and unrestricted egress"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = true

  ingress {
    description = "WireGuard UDP"
    from_port   = var.wireguard_port
    to_port     = var.wireguard_port
    protocol    = "udp"
    cidr_blocks = var.wireguard_allowed_cidrs
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wireguard-sg"
  }
}

resource "aws_eip" "wireguard" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "wireguard-eip"
  }
}

resource "aws_ssm_parameter" "client_config" {
  name        = var.client_config_parameter_name
  description = "WireGuard client configuration generated during EC2 bootstrap"
  type        = "SecureString"
  value       = "pending-initialization"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name = "wireguard-client-config"
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "wireguard" {
  name_prefix        = "wireguard-ec2-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "wireguard-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.wireguard.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "client_config_write" {
  statement {
    sid       = "WriteWireGuardClientConfig"
    effect    = "Allow"
    actions   = ["ssm:PutParameter"]
    resources = [aws_ssm_parameter.client_config.arn]
  }
}

resource "aws_iam_role_policy" "client_config_write" {
  name_prefix = "wireguard-client-config-"
  role        = aws_iam_role.wireguard.id
  policy      = data.aws_iam_policy_document.client_config_write.json
}

resource "aws_iam_instance_profile" "wireguard" {
  name_prefix = "wireguard-"
  role        = aws_iam_role.wireguard.name
}

resource "aws_instance" "wireguard" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.wireguard.id]
  associate_public_ip_address = true
  source_dest_check           = false
  iam_instance_profile        = aws_iam_instance_profile.wireguard.name

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    aws_region               = var.region
    client_address           = var.client_address
    client_allowed_ips       = join(", ", var.client_allowed_ips)
    client_config_parameter  = aws_ssm_parameter.client_config.name
    client_dns_servers       = join(", ", var.client_dns_servers)
    client_mtu               = var.client_mtu
    endpoint_ip              = aws_eip.wireguard.public_ip
    server_address           = var.server_address
    wireguard_port           = var.wireguard_port
  })
  user_data_replace_on_change = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  depends_on = [
    aws_iam_role_policy.client_config_write,
    aws_iam_role_policy_attachment.ssm_core,
    aws_route_table_association.public,
  ]

  tags = {
    Name = "wireguard-server"
  }
}

resource "aws_eip_association" "wireguard" {
  allocation_id = aws_eip.wireguard.id
  instance_id   = aws_instance.wireguard.id
}
