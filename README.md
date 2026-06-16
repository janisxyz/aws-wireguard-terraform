# AWS WireGuard Terraform Deployment

Deploys a secure WireGuard VPN server on AWS EC2 (t3.micro) in **eu-central-2 (Zurich)**.

## Prerequisites
- AWS account with permissions
- AWS CloudShell recommended

## Setup in AWS CloudShell

```bash
git clone https://github.com/janisxyz/aws-wireguard-terraform.git
cd aws-wireguard-terraform

# Install Terraform if needed
sudo apt-get update && sudo apt-get install -y terraform

terraform init
terraform plan
terraform apply -auto-approve
```

## Post-Deploy
```bash
terraform output wireguard_server_ip
aws ssm get-parameter --name "/wireguard/client-config" --with-decryption --query Parameter.Value --output text > client.conf
qrencode -t ansiutf8 < client.conf
```

## Destroy
`terraform destroy -auto-approve`

Costs: Low (~$5-10/month for t3.micro). Free Tier eligible in many cases.

Region: eu-central-2 (Zurich)