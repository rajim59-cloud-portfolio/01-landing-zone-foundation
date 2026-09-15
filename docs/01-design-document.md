# Landing Zone Foundation — Design Document

**Project:** 01-landing-zone-foundation
**Author:** Mehmed Hasan Rajim
**Status:** Draft → Review → Approved
**Version:** 1.0
**Last Updated:** 2026-09-26
**Target Region:** eastus (US East)
**IaC Tool:** Terraform

---

## 1. Executive Summary

This project delivers a production-style Azure Landing Zone foundation built
entirely with Terraform and deployed via GitHub Actions. It provides the
minimum governance, networking, identity, and cost guardrails required before
any workload can be safely deployed in an enterprise Azure environment.

The scope is intentionally small: one subscription, one Hub VNet, two Spoke
VNets, a small set of Azure Policies, RBAC groups, and a budget alert. The
goal is not to replicate Microsoft's full Enterprise-Scale Landing Zone, but
to demonstrate that I understand *why* each piece exists and how they connect
—at a level appropriate for a junior cloud engineer.

**One-line pitch:**
> A minimal, fully automated Azure Landing Zone that enforces governance,
> isolates workloads, and keeps monthly cost under $20.

---

## 2. Background & Motivation

Before any application can be deployed to Azure in a real organization,
several things must already exist:

- A **network foundation** (VNets, subnets, routing, firewall rules)
- **Governance** (mandatory tags, allowed regions, deny public access)
- **Identity & access** (groups, RBAC roles, least privilege)
- **Cost controls** (budgets, alerts, tagging strategy)
- **Monitoring** (centralized logs, basic alerts)

Without these, every workload team ends up building their own versions,
causing drift, security gaps, and unexpected costs. A **Landing Zone** is
the shared foundation that solves this problem once, centrally.

This project simulates that foundation at a scale I can build, deploy, and
explain end-to-end as a junior engineer.

**Why I built this:**
- To prove I understand cloud governance, not just resource creation.
- To practice Infrastructure-as-Code with modular Terraform.
- To demonstrate a real CI/CD workflow with manual approval gates.
- To show cost-awareness from day one.

---

## 3. Scope

### 3.1 In-Scope

- **Networking**
  - 1 Hub VNet (`10.0.0.0/16`) with dedicated subnets
  - 2 Spoke VNets (`10.1.0.0/16`, `10.2.0.0/16`)
  - VNet Peering (Hub ↔ each Spoke)
  - Network Security Groups (NSGs) with baseline rules
- **Governance**
  - Management Group hierarchy (modeled in code, simulated at deploy time)
  - Azure Policy: mandatory tags, allowed regions
  - Policy assignment at subscription scope
- **Identity & Access**
  - 2 Entra ID groups: `cloud-engineers`, `auditors`
  - RBAC role assignments (least privilege)
  - 1 custom role: `Network-Reader`
- **Cost Management**
  - Budget with alerts at 50%, 75%, 90%, 100%
  - Tag-based cost tracking (`Environment`, `CostCenter`, `Owner`)
- **Monitoring**
  - 1 Log Analytics Workspace
  - Diagnostic settings for NSGs and VNet
  - 2 alert rules (budget threshold, NSG deny spikes)

### 3.2 Out-of-Scope (Explicitly Excluded)

The following are **intentionally not included**. They would be
over-engineering for a junior portfolio project and add cost or
complexity without proportional learning value:

- ❌ Azure Firewall (evaluated but deferred—see ADR-003)
- ❌ Azure Bastion
- ❌ AKS / Kubernetes
- ❌ Multi-subscription deployment
- ❌ Azure Lighthouse / delegated governance
- ❌ ExpressRoute or VPN Gateway
- ❌ Private DNS Zones
- ❌ Multi-region active-active setup
- ❌ Third-party security tooling

These may appear in future phases (see Section 10) but are out of scope
for v1.0.0.

---

## 4. Requirements

### 4.1 Functional Requirements

| ID    | Requirement                                                    | Priority |
|-------|----------------------------------------------------------------|----------|
| FR-1  | Hub VNet and 2 Spoke VNets must be created in `eastus`.        | Must     |
| FR-2  | All VNets must be peered (Hub ↔ each Spoke, bidirectional).    | Must     |
| FR-3  | NSGs must be attached to all subnets with baseline rules.      | Must     |
| FR-4  | Azure Policy must deny deployments without required tags.      | Must     |
| FR-5  | Azure Policy must deny deployments outside `eastus`.           | Must     |
| FR-6  | Budget alert must trigger at 50%, 75%, 90%, 100% of $20.       | Must     |
| FR-7  | Log Analytics Workspace must receive NSG flow logs.            | Should   |
| FR-8  | A demo must show a policy violation failing a deployment.      | Should   |

### 4.2 Non-Functional Requirements

| ID     | Requirement                                                     |
|--------|-----------------------------------------------------------------|
| NFR-1  | Entire infrastructure defined in Terraform (no portal clicks).  |
| NFR-2  | Single command deploy and single command destroy.               |
| NFR-3  | CI runs `terraform plan` on every PR; CD applies on merge.      |
| NFR-4  | No secrets in code; all secrets via GitHub Secrets / Key Vault. |
| NFR-5  | Monthly cost must stay under $20 (with cleanup discipline).     |
| NFR-6  | All resources follow the project naming convention.             |
| NFR-7  | README must be sufficient for a stranger to reproduce the setup.|

---

## 5. Architecture Overview

### 5.1 High-Level Topology

[Architecture diagram will be embedded here — see docs/02-architecture.png]

The Landing Zone consists of:

```
┌─────────────────────────────────────────────────────────┐
│                    Azure Subscription                    │
│                                                          │
│   ┌──────────────┐      Peering      ┌──────────────┐   │
│   │  Hub VNet    │◄─────────────────►│ Spoke-App    │   │
│   │ 10.0.0.0/16  │                    │ 10.1.0.0/16  │   │
│   │              │      Peering      ┌──────────────┐   │
│   │  - Gateway   │◄─────────────────►│ Spoke-Data   │   │
│   │  - Shared    │                    │ 10.2.0.0/16  │   │
│   └──────────────┘                    └──────────────┘   │
│                                                          │
│   ┌──────────────────────────────────────────────────┐  │
│   │         Log Analytics Workspace                   │  │
│   │         (centralized logging)                     │  │
│   └──────────────────────────────────────────────────┘  │
│                                                          │
│   ┌──────────────────────────────────────────────────┐  │
│   │         Azure Policy (subscription scope)         │  │
│   │  - Mandatory tags  - Allowed regions              │  │
│   └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 5.2 Subnet Design

**Hub VNet (`10.0.0.0/16`)**
| Subnet Name    | CIDR          | Purpose                          |
|----------------|---------------|----------------------------------|
| `snet-shared`  | 10.0.1.0/24   | Reserved for future shared svcs  |
| `snet-mgmt`    | 10.0.2.0/24   | Reserved for management/jump     |

**Spoke-App VNet (`10.1.0.0/16`)**
| Subnet Name    | CIDR          | Purpose                          |
|----------------|---------------|----------------------------------|
| `snet-app`     | 10.1.1.0/24   | Application workloads            |

**Spoke-Data VNet (`10.2.0.0/16`)**
| Subnet Name    | CIDR          | Purpose                          |
|----------------|---------------|----------------------------------|
| `snet-data`    | 10.2.1.0/24   | Data workloads                   |

### 5.3 Design Decisions

Key architectural decisions are documented separately as ADRs:

- [ADR-001: Why Hub-Spoke over Full Mesh](adr/001-why-hub-spoke.md)
- [ADR-002: Why Terraform over Bicep](adr/002-why-terraform.md)
- [ADR-003: Why Azure Firewall is Deferred](adr/003-why-firewall-deferred.md)

---

## 6. Assumptions & Constraints

### Assumptions
- A single Azure subscription is available (Free Tier eligible).
- The deployer has Contributor access at subscription scope.
- Region `eastus` supports all required services in the Free Tier.
- Only one operator (me) will deploy this in a demo environment.

### Constraints
- **Budget:** Monthly cost must not exceed $20.
- **Region:** Only `eastus` will be used for all resources.
- **Scale:** Designed for 1 Hub + 2 Spokes (not hundreds).
- **Compliance:** No regulated data; no PCI/HIPAA requirements.
- **Time:** Project must be completed within 3 weeks part-time.

---

## 7. Risks & Mitigations

| Risk                                   | Likelihood | Impact | Mitigation                                       |
|----------------------------------------|------------|--------|--------------------------------------------------|
| Cost overrun from forgotten resources  | Medium     | High   | Budget alert at $10; `terraform destroy` guide   |
| Policy blocks legitimate deployments   | Low        | Medium | Test policies in audit mode first                |
| VNet peering misconfiguration          | Medium     | Low    | Non-overlapping CIDR ranges; validate in plan    |
| Secrets accidentally committed         | Low        | High   | `.gitignore`, GitHub Secrets, pre-commit hook    |
| Region restriction too tight           | Low        | Low    | Start with `eastus` + `westeurope` as allowed    |

---

## 8. Cost Summary

Estimated monthly cost (with cleanup discipline):

| Resource                        | Estimated Monthly Cost |
|---------------------------------|------------------------|
| VNets, Subnets, Peering         | $0 (free)              |
| NSGs                            | $0 (free)              |
| Azure Policy                    | $0 (free tier)         |
| Entra ID Groups                 | $0 (free tier)         |
| Log Analytics (5 GB/day cap)    | ~$5                    |
| Budget Alerts                   | $0 (free)              |
| **Estimated Total**             | **~$5/month**          |

**Full cost breakdown:** see [`06-cost-estimate.md`](06-cost-estimate.md)

---

## 9. Success Criteria

The project is considered complete when:

- [ ] All resources deploy via `terraform apply` in one command.
- [ ] Policy violation demo fails as expected (documented with screenshot).
- [ ] Budget alert triggers and is captured in a screenshot.
- [ ] Log Analytics receives NSG flow logs (verified via KQL query).
- [ ] CI/CD pipeline (plan + apply with manual approval) works end-to-end.
- [ ] Demo video (2–3 minutes) is recorded and linked in README.
- [ ] All items in the Master Requirements checklist are ticked.

---

## 10. Future Roadmap (Out of Scope for v1.0.0)

These are documented to show forward thinking, but are **not** part of
this release:

- **v1.1:** Add Azure Bastion for secure VM access
- **v1.2:** Add Private DNS Zones for internal name resolution
- **v1.3:** Add Defender for Cloud baseline recommendations
- **v2.0:** Multi-subscription model with Management Group policies

---

## 11. References

- [Azure Landing Zone Design Principles (Microsoft)](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-principles)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Project ADRs](adr/)
- [Master Requirements](../../MASTER-REQUIREMENTS.md)

---

## 12. Document History

| Version | Date       | Author      | Change Summary    |
|---------|------------|-------------|-------------------|
| 0.1     | 2026-09-15 | Mehmed Hasan Rajim | Initial draft     |
| 1.0     | 2026-09-15 | Mehmed Hasan Rajim | Approved for build|
```

---