# Azure Landing Zone Foundation

> A governed, secure, and scalable Azure platform foundation deployed with Terraform — following Microsoft's Cloud Adoption Framework (CAF).

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.6-7B42BC?logo=terraform)](https://www.terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Landing%20Zone-0078D4?logo=microsoftazure)](https://azure.microsoft.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🎯 Problem Statement

Enterprises adopting Azure without a structured platform foundation quickly encounter critical challenges:

- Scattered subscriptions lacking unified governance and organizational guardrails
- Overlapping CIDR address spaces creating unroutable network conflicts
- Lack of proactive policy enforcement resulting in security vulnerabilities and budget overruns
- Workload teams repeatedly rebuilding networking, DNS, logging, and identity from scratch

This repository solves that by delivering a **codified enterprise landing zone** — a modular, automated Terraform framework that deploys a secure shared platform ready to host downstream applications.

---

## 🏗️ Architecture


```

```
                           ┌────────────────────────────────┐
                           │       Management Groups        │
                           │   (Platform, Workload, Sandbox)│
                           └───────────────┬────────────────┘
                                           │
                           ┌───────────────▼────────────────┐
                           │            Hub VNet            │
                           │  - Azure Firewall (Basic)      │
                           │  - Azure Bastion Host          │
                           │  - Central Private DNS Zones   │
                           │  - Central Log Analytics       │
                           └───────────────┬────────────────┘
                                           │
                   ┌───────────────────────┴───────────────────────┐
                   │                                               │
          ┌────────▼────────┐                             ┌────────▼────────┐
          │   Spoke: App    │                             │   Spoke: Data   │
          │  (Compute/Web)  │                             │ (DB/Private EP) │
          └─────────────────┘                             └─────────────────┘

```

```

For complete subnet breakdowns, Route Table topologies, and packet flow logic, refer to [docs/architecture.md](docs/architecture.md).

---

## 📦 What Gets Deployed

- **Hub-Spoke Topology:** Fully peered VNet mesh with deterministic User-Defined Routes (UDR) routing all outbound traffic (`0.0.0.0/0`) through Azure Firewall.
- **Central Private DNS:** Private DNS zones (`privatelink.azurewebsites.net`, `privatelink.postgres.database.azure.com`, `privatelink.vaultcore.azure.net`) linked across all VNets.
- **Perimeter Security:** Central Azure Firewall (Basic) default-deny egress inspection and Azure Bastion for secure administrative access without public IPs.
- **Automated Governance:** Subscription-level Azure Policy enforcement blocking untagged deployments, unauthorized regions, and public IP allocations.
- **Identity & RBAC:** Entra ID security groups (`network-admins`, `cloud-engineers`, `security-auditors`) configured with scoped least-privilege role assignments.
- **Security Posture (CSPM):** Microsoft Defender for Cloud foundational posture monitoring paired with automated security contact routing.
- **Subscription Vending:** Reusable simulation of the Azure Verified Module (AVM) vending pattern for streamlined workload provisioning.
- **Cost Guardrails:** Subscription and resource group consumption budgets with automated threshold notifications.

---

## 🚀 Quick Start (Windows & PowerShell Native)

### Prerequisites
- Azure subscription with Owner or Contributor + User Access Administrator permissions
- Terraform >= 1.6
- Azure CLI authenticated (`az login`)
- PowerShell 7+ or Windows PowerShell with `RemoteSigned` execution policy

### Deploy

```powershell
# 1. Run local tag & governance pre-flight check
.\scripts\validate-tags.ps1

# 2. Bootstrap remote state storage backend (one-time)
.\scripts\bootstrap.ps1

# 3. Initialize and provision landing zone infrastructure
cd infra
terraform init
terraform plan -var-file="local.tfvars" -out=tfplan
terraform apply tfplan

```

### Clean Teardown (Zero-Cost Target)

```powershell
# Execute automated teardown back to $0.00 baseline
cd F:\rajim59-cloud-portfolio\01-landing-zone-foundation
.\scripts\destroy.ps1

```

---

## 📚 Documentation & Workload Integration

| Documentation File | Description |
| --- | --- |
| [HANDOVER.md](https://www.google.com/search?q=HANDOVER.md&utm_source=gemini) | **Integration contract** detailing outputs, remote state usage, and rules for downstream projects (Project 2+) |
| [docs/architecture.md](docs/architecture.md)| Detailed network topology, CIDR allocations, DNS routing, and Management Group hierarchy |
| [docs/decisions.md](docs/decisions.md) | Architecture Decision Records (ADRs) justifying SKU choices, routing logic, and trade-offs |
| [docs/cost.md](docs/cost.md) | Detailed cost modeling, SKU optimizations, and zero-cost ephemeral lab strategies |
| [docs/testing.md](docs/testing.md) | Audit logs, execution outputs, and evidence across all 13 validation test scenarios |

---

## 🔒 Security & Compliance Matrix

* **Zero Public IP Surface:** Workload subnets strictly forbid public IP allocation via Azure Policy (`deny-public-ip`).
* **Inspection & Isolation:** All egress routes hop directly through the central firewall private appliance (`10.0.1.4`).
* **Centralized Resolution:** Workload endpoints resolve private Azure services exclusively via Hub Private DNS Links.
* **Least-Privilege RBAC:** Application teams are scoped strictly to their respective workload resource groups without hub modification privileges.
* **Posture Auditing:** Microsoft Defender for Cloud continuously evaluates baseline security benchmarks at zero platform cost.

---

## 🧪 Testing & Verification

This platform foundation is validated against a comprehensive 13-point test suite spanning static syntax analysis, policy enforcement gates, routing controls, and zero-cost teardown:

* **Tests 1–4:** Syntax formatting, dry-run dependency validation, policy DENY, and policy ALLOW assertions.
* **Tests 5–8:** Bidirectional peering verification, firewall egress interception, RBAC group enforcement, and zero-cost destruction.
* **Tests 9–13:** Management Group hierarchy review, Private DNS resolution, Defender CSPM activation, Subscription Vending execution, and Windows automation runs.

Complete audit logs and screenshots are cataloged in [docs/testing.md](docs/testing.md).

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).