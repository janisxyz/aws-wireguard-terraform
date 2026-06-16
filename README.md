# AWS WireGuard Terraform Deployment

Deploy a secure WireGuard VPN server on AWS EC2 (**t3.micro** in **eu-central-2** Zurich) using Terraform.

## Prerequisites
- AWS account with necessary IAM permissions (EC2, VPC, SSM Parameter Store)
- AWS CloudShell (recommended - pre-authenticated)

## 1. Install Terraform in AWS CloudShell

Run these commands once in CloudShell:

```bash
sudo apt-get update -y

# Install HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update && sudo apt-get install terraform -y

# Verify installation
terraform version
```

## 2. Clone & Deploy

```bash
git clone https://github.com/janisxyz/aws-wireguard-terraform.git
cd aws-wireguard-terraform

# (Optional) Review/edit variables.tf for your IP (allowed_ssh_cidr)

terraform init
terraform plan
terraform apply -auto-approve
```

## Post-Deployment
- Get server IP: `terraform output wireguard_server_ip`
- Retrieve client config securely:
  ```bash
  aws ssm get-parameter --name "/wireguard/client-config" --with-decryption --query "Parameter.Value" --output text > ~/wireguard-client.conf
  ```
- Display QR code:
  ```bash
  sudo apt install qrencode -y
  qrencode -t ansiutf8 < ~/wireguard-client.conf
  ```

## Cleanup
```bash
terraform destroy -auto-approve
```

## Notes
- **Region**: `eu-central-2` (Zurich)
- **Instance Type**: `t3.micro` (Free Tier eligible)
- **Security**: IMDSv2, encrypted EBS, secrets in SSM, WireGuard UDP only.
- Expected cost: Low (~$5-10/month)

For SSH access (if enabled), update `allowed_ssh_cidr` to your IP.