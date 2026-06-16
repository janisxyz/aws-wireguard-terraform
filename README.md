# AWS WireGuard Terraform Deployment

Deploys a single-client WireGuard VPN server on AWS EC2 with:

- a stable Elastic IP
- an encrypted gp3 root volume
- IMDSv2 enforcement
- no inbound SSH port
- Systems Manager Session Manager access
- a generated client profile stored as an encrypted SSM SecureString
- IPv4 forwarding, NAT and automatic WireGuard startup

The default region is `eu-central-2` (Zurich) and the default instance type is `t3.micro`.

## Prerequisites

- An AWS account and AWS CLI credentials with permission to manage EC2, VPC, IAM and SSM resources
- AWS CloudShell or another Linux shell
- Terraform 1.5 or newer

## Install Terraform in AWS CloudShell

```bash
TF_VERSION=1.14.6 && cd /tmp && rm -f terraform "terraform_${TF_VERSION}_linux_amd64.zip" && curl -fSLO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" && unzip -o "terraform_${TF_VERSION}_linux_amd64.zip" && sudo install -m 0755 terraform /usr/local/bin/terraform && hash -r && terraform version
```

## Deploy

```bash
cd "$HOME" && rm -rf aws-wireguard-terraform && git clone https://github.com/janisxyz/aws-wireguard-terraform.git && cd aws-wireguard-terraform && terraform init && terraform fmt -check && terraform validate && terraform plan -out=tfplan && terraform apply tfplan
```

Terraform returns after AWS creates the infrastructure. The instance may need another minute to finish cloud-init and publish the client profile.

## Retrieve the client profile

```bash
until aws ssm get-parameter --region eu-central-2 --name /wireguard/client-config --with-decryption --query 'Parameter.Value' --output text > "$HOME/wireguard-client.conf" 2>/dev/null && ! grep -q '^pending-initialization$' "$HOME/wireguard-client.conf"; do sleep 5; done && chmod 600 "$HOME/wireguard-client.conf" && cat "$HOME/wireguard-client.conf"
```

Import `~/wireguard-client.conf` into the WireGuard app.

To display it as a QR code after installing `qrencode`:

```bash
command -v qrencode >/dev/null || { sudo dnf install -y qrencode 2>/dev/null || sudo apt-get update && sudo apt-get install -y qrencode; }
qrencode -t ansiutf8 < "$HOME/wireguard-client.conf"
```

## Useful outputs

```bash
terraform output wireguard_server_ip
terraform output -raw client_config_command
terraform output -raw ssm_session_command
```

## Troubleshooting

Open a Session Manager shell using the command shown by:

```bash
terraform output -raw ssm_session_command
```

Then inspect bootstrap and WireGuard state:

```bash
sudo cloud-init status --wait
sudo tail -n 200 /var/log/wireguard-bootstrap.log
sudo systemctl status wg-quick@wg0 --no-pager
sudo wg show
```

## Customize

Create a `terraform.tfvars` file, for example:

```hcl
region                  = "eu-central-2"
instance_type           = "t3.micro"
wireguard_port          = 51820
wireguard_allowed_cidrs = ["0.0.0.0/0"]
client_dns_servers      = ["1.1.1.1", "1.0.0.1"]
client_mtu              = 1380
```

Restricting `wireguard_allowed_cidrs` is possible when the client has a predictable source IP. Mobile connections generally do not.

## Destroy

```bash
terraform destroy -auto-approve
```

The SSM parameter is Terraform-managed, so destroy removes it together with the EC2 instance, Elastic IP, IAM role and network resources.

## Cost and security notes

This deployment creates billable AWS resources, including EC2, EBS, a public IPv4 address and data transfer. Check current AWS pricing for the selected region and account. The generated client configuration contains a private key; keep the downloaded file and access to the SSM parameter restricted.
