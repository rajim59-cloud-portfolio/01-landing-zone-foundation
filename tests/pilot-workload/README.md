# Pilot Workload

A small test VM deployed into the landing zone to verify:
- Networking (Bastion access, no public IP)
- Governance (required tags, policy DENY)
- Identity (Managed Identity)
- Monitoring (diagnostic settings → central LAW)

## How it works

This folder has its **own Terraform state** (`pilot-workload.tfstate`) and reads the landing zone outputs via `terraform_remote_state`.

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars
# Fill in subscription_id
terraform init
terraform apply