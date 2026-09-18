# Architecture Decision Records (ADR)

This document records the key architectural decisions, alternative options evaluated, and trade-offs accepted across the lifecycle of the Azure Landing Zone Foundation.

Each entry adheres to the formal **ADR framework**: Context → Decision → Alternatives Considered → Consequences.

---

## Decision 1: Hub-Spoke Topology over Mesh or Flat Network

- **Status:** Accepted
- **Date:** 2026-09-16

### Context
The platform foundation must support enterprise multi-tenant scaling (50+ prospective workloads) with centralized perimeter defense, deterministic egress inspection, and strict lateral isolation between spoke networks.

### Decision
Implement a centralized **Hub-Spoke** virtual network topology aligned with the Microsoft Cloud Adoption Framework (CAF). The Hub manages shared security infrastructure (Azure Firewall, Azure Bastion, Central Private DNS Zones, Log Analytics). Workloads reside inside isolated spoke networks peered exclusively to the Hub.

### Alternatives Considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **Hub-Spoke** | Centralized policy enforcement, deterministic egress, lateral segmentation | Hub availability dependency (mitigated by Availability Zones) | ✅ Chosen |
| **Full Mesh** | Direct spoke-to-spoke low-latency routing | Peering complexity scales quadratically ($n(n-1)/2$), unmanageable NSG matrices | ❌ Rejected |
| **Flat VNet** | Minimal routing overhead, lowest baseline cost | Zero subnet isolation, high blast radius, non-compliant with zero-trust | ❌ Rejected |

### Consequences
- **Positive:** Centralized egress firewall inspection, zero lateral traffic between workloads without explicit routing rules, unified logging.
- **Negative:** Fixed baseline cost for Hub inspection appliances.

---

## Decision 2: Azure Firewall Basic SKU over Standard/Premium

- **Status:** Accepted
- **Date:** 2026-09-16

### Context
A centralized network firewall is required to enforce zero-trust egress inspection and default-deny perimeter filtering across all peered spokes.

### Decision
Deploy the **Azure Firewall Basic SKU** with a dedicated management subnet (`AzureFirewallManagementSubnet`).

### Alternatives Considered

| Option | Est. Monthly | Key Capabilities | Verdict |
|---|---|---|---|
| **Basic SKU** | ~$288 / mo | Stateful L3–L4 filtering, FQDN filtering, threat intelligence alert mode | ✅ Chosen |
| **Standard SKU** | ~$900+ / mo | Up to 30 Gbps throughput, Layer 7 deep application inspection, threat intel deny | ❌ Rejected for Foundation Lab |
| **Premium SKU** | ~$1,750+ / mo | IDPS (Intrusion Detection/Prevention), TLS inspection, URL categorization | ❌ Rejected for Foundation Lab |

### Consequences
- **Positive:** Over 68% cost reduction compared to Standard SKU while providing full route validation and stateful rule enforcement.
- **Negative:** Throughput constrained to ~250 Mbps and lacks TLS termination (acceptable for foundational validation; upgradeable in production without topology refactoring).

---

## Decision 3: Terraform over Azure Bicep / ARM Templates

- **Status:** Accepted
- **Date:** 2026-09-16

### Context
Infrastructure as Code (IaC) tooling must ensure reproducible provisioning, strict module encapsulation, dependency resolution, and enterprise state management.

### Decision
Standardize on **HashiCorp Terraform (>= 1.6)** utilizing the official `hashicorp/azurerm` and `hashicorp/azuread` providers.

### Alternatives Considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **Terraform** | Multi-cloud parity, mature dependency DAG engine, immutable plan artifacts | State lock management and remote backend requirement | ✅ Chosen |
| **Azure Bicep** | Native Azure DSL, zero state management overhead | Azure-only ecosystem, vendor lock-in, less ecosystem module reuse | ❌ Rejected |
| **ARM Templates** | Native JSON engine | Highly verbose, lack of dynamic readability and modular composition | ❌ Rejected |

### Consequences
- **Positive:** Industry-standard transferable skill set, deterministic dry-run planning (`terraform plan`), modular composition.
- **Negative:** Requires remote backend initialization (addressed in Decision 4).

---

## Decision 4: Azure Blob Storage Remote Backend with State Locking

- **Status:** Accepted
- **Date:** 2026-09-16

### Context
Terraform state holds sensitive resource metadata, IP assignments, and lock identifiers. It must be centrally stored, encrypted, and protected against concurrent execution corruption.

### Decision
Use an **Azure Storage Account (Blob Container)** with native blob lease locking and server-side encryption (TLS 1.2, private endpoints/firewalls).

### Alternatives Considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **Azure Storage Backend** | Native platform integration, blob lease locking, versioning recovery | Requires one-time bootstrap orchestration | ✅ Chosen |
| **Terraform Cloud** | Managed SaaS, built-in VCS runners | External SaaS dependency and credential forwarding overhead | ❌ Rejected |
| **Local State File** | Zero operational setup | Risk of state loss, zero team collaboration, concurrent write corruption | ❌ Rejected |

### Consequences
- **Positive:** Safe concurrent executions, state versioning rollback capabilities, zero SaaS license dependencies.
- **Negative:** Requires a one-time bootstrap execution via `bootstrap.ps1`.

---

## Decision 5: Centralized Hub Private DNS Zones vs Distributed Spoke DNS

- **Status:** Accepted
- **Date:** 2026-09-17

### Context
Workloads deploying Private Endpoints (Key Vault, PostgreSQL, Web Apps) require deterministic private IP resolution without split-brain DNS anomalies.

### Decision
Provision **centralized Private DNS Zones in the Hub Network Resource Group (`rg-hub-network`)** and link them to the Hub and all connected Spoke VNets with auto-registration disabled.

### Alternatives Considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **Centralized Hub DNS** | Single pane of glass, no duplicate DNS zones, consistent multi-vnet resolution | Requires centralized VNet link automation | ✅ Chosen |
| **Distributed Per-Spoke DNS** | Decentralized management per app team | Split-brain queries, duplicate resource costs, unresolvable cross-spoke names | ❌ Rejected |
| **Custom IaaS DNS VMs** | Custom bind flexibility | High VM compute costs, OS patching overhead, non-cloud-native | ❌ Rejected |

### Consequences
- **Positive:** Centralized management, eliminates DNS drift, cuts private DNS hosting costs by over 60%.
- **Negative:** Platform team manages central DNS links for newly onboarded spokes.

---

## Decision 6: Foundational CSPM (Free) vs Paid Defender for Cloud Plans

- **Status:** Accepted
- **Date:** 2026-09-17

### Context
Continuous compliance evaluation and regulatory benchmark auditing (e.g., Microsoft Cloud Security Benchmark) are necessary without incurring enterprise server-licensing charges during platform validation.

### Decision
Activate **Microsoft Defender for Cloud Foundational Cloud Security Posture Management (CSPM) on the Free Tier** (`CloudPosture`) paired with automated security contact routing.

### Alternatives Considered

| Option | Est. Monthly | Capabilities | Verdict |
|---|---|---|---|
| **Foundational CSPM (Free)** | $0.00 | Continuous MCSB benchmark auditing, secure score, asset inventory | ✅ Chosen |
| **Defender CSPM (Paid)** | ~$5.00 / resource / mo | Attack path analysis, agentless vulnerability scanning, governance rules | ❌ Rejected for Foundation Lab |
| **Defender for Servers Plan 2** | ~$15.00 / server / mo | MDE endpoint protection, vulnerability management, just-in-time VM access | ❌ Deferred to Workload Phase |

### Consequences
- **Positive:** Zero financial impact ($0.00) while providing automated security alerting and continuous compliance scoring.
- **Negative:** Advanced agentless scanning and attack path graphs require paid upgrade in production.

---

## Decision 7: Simulated AVM Subscription Vending Pattern

- **Status:** Accepted
- **Date:** 2026-09-17

### Context
Application teams need a codified onboarding model that automates VNet provisioning, peering, routing, and budget assignment without requiring enterprise Enterprise Agreement (EA) tenant-level billing creation access in lab environments.

### Decision
Implement a **simulated Azure Verified Module (AVM) subscription vending module** (`modules/subscription-vending`). It mirrors production subscription vending mechanics (resource group encapsulation, dedicated CIDR spoke provisioning, bidirectional hub peering, default firewall routing, and consumption budgets) within the active subscription scope.

### Alternatives Considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **Simulated AVM Pattern** | Complete production workflow validation, zero extra subscription overhead | Scoped inside single subscription boundary | ✅ Chosen |
| **Production AVM (`azurerm_subscription`)** | Fully isolated subscriptions | Requires EA or MCA enterprise billing agreement credentials | ❌ Incompatible with Dev Lab |
| **Manual Application Onboarding** | Quickest initial setup | Configuration drift, non-standardized routing, unscalable platform operations | ❌ Rejected |

### Consequences
- **Positive:** Downstream applications (Project 2+) can be onboarded programmatically with identical inputs, outputs, and governance constraints.
- **Negative:** Full management group boundary placement remains documented in architectural contracts rather than live tenant-root execution.

---

## Decision 8: Windows-Native Automation (PowerShell/Batch) over Linux Bash

- **Status:** Accepted
- **Date:** 2026-09-17

### Context
The platform engineering environment operates natively on Windows 11 without requiring WSL (Windows Subsystem for Linux) or external Bash runtimes for core operational tasks.

### Decision
Standardize all operational lifecycle, pre-flight checks, and teardown scripts on **PowerShell (`.ps1`) and Batch (`.bat`) wrappers**.

### Alternatives Considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **Native PowerShell / Batch** | Out-of-the-box Windows execution, native Azure CLI integration, no extra tools | Requires Windows-friendly path syntax | ✅ Chosen |
| **Bash Shell Scripts (`.sh`)** | Unix standard, native in Linux CI | Requires Git Bash or WSL; execution failures in raw Windows cmd/powershell | ❌ Rejected |
| **Python Automation** | Cross-platform | Additional runtime and package management (`pip`, virtualenv) dependency | ❌ Rejected |

### Consequences
- **Positive:** Frictionless local administration, reliable execution on standard Windows developer workstations.
- **Negative:** GitHub Actions CI pipelines execute natively on Linux runners (`ubuntu-latest`) and run cross-platform Azure CLI/Terraform steps directly without calling local 