# Azure Landing Zone Foundation

> A governed, secure, and scalable Azure foundation deployed with Terraform — following Microsoft's Cloud Adoption Framework (CAF).

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.6-7B42BC?logo=terraform)](https://www.terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Landing%20Zone-0078D4?logo=microsoftazure)](https://azure.microsoft.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🎯 Problem Statement

Enterprises adopting Azure without a foundation quickly end up with:

- Scattered subscriptions with no central governance
- Overlapping network CIDR blocks across teams
- No policy enforcement → security and cost drift
- Every new app rebuilds networking, identity, and logging from scratch

This project solves that by providing a **codified landing zone** — a single `terraform apply` provisions the shared platform that every workload lands onto.

---

## 🏗️ Architecture

```
                  ┌─────────────────────────┐
                  │      Hub VNet           │
                  │  (Firewall, Bastion,    │
                  │   Log Analytics)        │
                  └──────────┬──────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
     ┌────────▼────────┐          ┌─────────▼────────┐
     │  Spoke: App     │          │  Spoke: Data     │
     │  (App Subnet)   │          │  (Data Subnet)   │
     └─────────────────┘          └──────────────────┘
```

See [docs/architecture.md](docs/architecture.md) for full CIDR plan, peering, and routing details.

---

## 📦 What Gets Deployed

- **Networking** — Hub-Spoke VNet topology with peering, route tables, NSG
- **Security** — Azure Firewall (Basic), Azure Bastion for private VM access
- **Governance** — Azure Policy (required tags, allowed regions, deny public IP)
- **Identity** — Entra ID groups + custom RBAC role (least-privilege)
- **Monitoring** — Central Log Analytics workspace with KQL queries and alerts
- **Cost Control** — Budget with alerts at 50% / 80% / 100%

---

## 🚀 Quick Start

### Prerequisites
- Azure subscription with Contributor access
- Terraform >= 1.6
- Azure CLI authenticated (`az login`)

### Deploy

```bash
# 1. Bootstrap the Terraform backend (one-time)
./scripts/bootstrap.sh

# 2. Initialize and deploy
cd infra
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Destroy (to zero cost)

```bash
./scripts/destroy.sh
```

---

## 📚 Documentation

| File | What's inside |
|------|---------------|
| [docs/architecture.md](docs/architecture.md) | Hub-Spoke topology, CIDR plan, peering |
| [docs/decisions.md](docs/decisions.md) | Why Hub-Spoke, why Basic SKU, trade-offs |
| [docs/cost.md](docs/cost.md) | Monthly cost estimate and reduction strategies |
| [docs/testing.md](docs/testing.md) | 8 test cases with screenshots and pass criteria |

---

## 🎬 Demo

▶️ [2-minute walkthrough video](docs/screenshots/) — policy enforcement, peering, and zero-cost destroy.

---

## 💰 Cost

| Resource | SKU | Est. Monthly |
|----------|-----|--------------|
| Azure Firewall | Basic | ~$290 |
| Azure Bastion | Basic | ~$140 |
| Log Analytics | Pay-as-you-go | ~$5–10 |
| VNet Peering | Data-based | ~$1–2 |
| **Total** |  | **~$436** |

> With daily `terraform destroy`, actual cost stays around **$50–100/month**.

See [docs/cost.md](docs/cost.md) for details.

---

## 🔒 Security Highlights

- No public IPs on workload subnets (enforced by Azure Policy)
- Private VM access via Azure Bastion
- OIDC federated credentials for CI/CD (no long-lived secrets)
- Least-privilege RBAC — custom role for network readers

---

## 🧪 Testing

This project is validated by 8 test cases — see [docs/testing.md](docs/testing.md).

---

## 📄 License

[MIT](LICENSE)