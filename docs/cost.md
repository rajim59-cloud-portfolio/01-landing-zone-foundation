# Cost Estimation & FinOps Guardrails

This document provides a comprehensive monthly cost model for the Azure Landing Zone Foundation (`malaysiawest`), detailing billable line items, architectural trade-offs, and FinOps lifecycle automation designed to maintain an ephemeral $0.00 operational run-rate.

---

## 1. Monthly Cost Estimate (Always-On Baseline)

The following baseline models a 24/7 always-on deployment in the primary deployment region (`malaysiawest` / `southeastasia`):

| Resource | Component / SKU | Pricing Metric | Est. Monthly (USD) |
|---|---|---|:---:|
| **Azure Firewall** | Basic SKU (`afw-hub`) | ~$0.395 / hour | ~$288.00 |
| **Azure Bastion** | Basic SKU (`bastion-hub`) | ~$0.190 / hour | ~$138.00 |
| **Public IPs** | Standard SKU (Firewall, Mgmt, Bastion × 3) | ~$0.005 / hour / IP | ~$10.80 |
| **Central Log Analytics** | `law-landing-zone` (Pay-As-You-Go) | ~$2.76 / GB ingested (~2 GB/mo) | ~$5.50 |
| **Private DNS Zones** | 3 Zones + 7 VNet Links | $0.50/zone + $0.20/link | ~$2.90 |
| **Defender for Cloud** | Foundational CSPM (Free Tier) | $0.00 / resource | **$0.00** |
| **VNet Peering** | Hub ↔ Spokes (Data Ingress/Egress) | ~$0.01 / GB data transfer | ~$1.00 |
| **Terraform State** | `sttfstate...` (Standard LRS Hot Blob) | Storage & read/write operations | ~$0.20 |
| **Total Always-On Run-Rate** | | | **~$446.40 / month** |

---

## 2. FinOps Strategy: Ephemeral Zero-Cost Teardown

Because this infrastructure serves as a verified platform foundation, long-lived idle resources generate unnecessary enterprise waste. Costs are minimized through **ephemeral automated lifecycle management**.

### Operational Run-Rate Models

| Operating Model | Operational Pattern | Projected Spend (USD) |
|---|---|:---:|
| **Always-On Production** | 730 hours / month continuous operation | ~$446.40 |
| **Active Development Lab** | 40 hours / month (5 sessions × 8 hours) | ~$24.50 |
| **Portfolio Audit / Demonstration** | 2 hours / testing run + immediate teardown | **<$1.50** |
| **Quiescent Baseline (Post-Destroy)**| State Storage account & default watchers only | **$0.00** |

### Automated Cleanup Execution (Windows Native)

At the conclusion of verification or demonstration runs, teardown is executed via native PowerShell automation:

```powershell
# Automated clean destroy down to $0.00 baseline
cd F:\rajim59-cloud-portfolio\01-landing-zone-foundation
.\scripts\destroy.ps1

```

---

## 3. Architecture-Level Cost Optimizations

1. **Azure Firewall Basic vs Standard:**
* Deployed **Firewall Basic** (~$288/month) instead of Standard (~$900/month). Basic provides complete L3–L7 stateful filtering, threat intelligence, and private routing verification without multi-gigabit throughput surcharges.


2. **Foundational Defender for Cloud (CSPM):**
* Explicitly configured `azurerm_security_center_subscription_pricing` to `Free` (`CloudPosture`), providing continuous compliance checks against the Microsoft Cloud Security Benchmark (MCSB) without enabling paid server plan licenses.


3. **Centralized Hub Private DNS Consolidation:**
* Consolidating Private DNS zones inside `rg-hub-network` and sharing them via VNet links prevents application teams from deploying duplicate Private DNS Zones per spoke, cutting private DNS management overhead by over 60%.


4. **Subnet Delegation Pre-allocation:**
* Reserved subnets (`GatewaySubnet`, `AzureBastionSubnet`, `FunctionSubnet`) avoid costly, disruptive IP re-architecting while incurring $0 in standby charges until actual compute instances or gateways are bound.



---

## 4. Policy-Enforced Cost Guardrails

Cost management is codified directly into the infrastructure deployment lifecycle through automated governance gates:

* **Subscription Consumption Budget (`budget-landing-zone`):**
* **Budget Cap:** Set to `$20.00/month` for the platform scope.
* **Automated Alerts:** Triggers notifications to `rajim59.dev@gmail.com` via Action Group `ag-email-alerts` at **80%** ($16.00) and **100%** ($20.00) actual burn.


* **Workload-Level Vending Budgets:**
* Downstream applications onboarded via `modules/subscription-vending` automatically instantiate dedicated resource-group budgets with isolated alerting rules.


* **Mandatory CostCenter Tagging:**
* Enforced via Azure Policy (`assign-require-tags`). Untagged resources are rejected at the ARM API gate before provisioning commences:
```hcl
tags = {
  CostCenter = "1001"
  Env        = "prod"
  Owner      = "Platform-Team"
  Project    = "LandingZone"
}

```




* **Local Pre-Deployment Validation:**
* The local `validate-tags.ps1` script blocks `terraform apply` if mandatory tags or region constraints are omitted, eliminating accidental misconfigured cloud charges.



---

## 5. Enterprise Production Scaling Path

For production enterprise workloads requiring higher scale, the following architectural upgrades would be adopted:

| Component | Foundation (Current Portfolio) | Enterprise Production Standard | Cost Delta |
| --- | --- | --- | --- |
| **Firewall** | Basic SKU (30 Mbps throughput) | Standard / Premium (IDPS, TLS Inspection) | +$600–$1,200/mo |
| **Bastion** | Basic SKU | Standard SKU with IP Connect & Native Client | +$150/mo |
| **Log Storage** | Pay-As-You-Go (30-day retention) | Dedicated Cluster / Commitment Tiers (365 days) | Volume-dependent |
| **Compute** | On-Demand Instances | 1-Year or 3-Year Azure Reserved Instances (RI) | 30% to 50% savings |
