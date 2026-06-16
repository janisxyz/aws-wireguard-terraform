# AWS WireGuard Terraform Deployment

Secure private WireGuard VPN server on AWS EC2.

## AWS CloudShell Setup
1. Open AWS CloudShell
2. Install Terraform if needed:
   ```bash
   sudo apt-get update && sudo apt-get install -y terraform
   ```

## Commands
```bash
terraform init
terraform plan
terraform apply
```

## Retrieve Config
Use `aws ssm get-parameter --name "/wireguard/client-config" --with-decryption`

## QR Code
`qrencode -t ansiutf8 < ~/wireguard-client.conf`

## Costs
Expect ~$5-10/month for t3.micro. Check Free Tier.

## Destroy
`terraform destroy`

Region: us-east-1, instance: t3.micro (configurable).