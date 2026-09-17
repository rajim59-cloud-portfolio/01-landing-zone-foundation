# Architecture Decisions

This document records the key architectural decisions, the alternatives considered, and the trade-offs accepted.

Each entry follows the **ADR (Architecture Decision Record)** format: Context → Decision → Alternatives → Consequences.

---

## Decision 1: Hub-Spoke Topology over Mesh

- **Status:** Accepted
- **Date:** 2026-09-16

### Context
We need a network topology that supports 50+ workloads with central governance, yet isolates each workload from others.

### Decision
Use **Hub-Spoke** topology. The Hub contains shared services (Firewall, Bastion, DNS). Each workload gets its own Spoke VNet peered to the Hub.

### Alternatives Considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **Hub-Spoke** | Centralized control, scalable, cost-effective | Hub becomes a single point of failure (mitigated by zone redundancy) | ✅ Chosen |
| **Mesh** | Direct spoke-to-spoke connectivity | Management complexity grows exponentially (n×(n-1)/2 peerings) | ❌ Rejected |
| **Flat VNet** | Simplest | No isolation, NSG becomes unmanageable | ❌ Rejected |

### Consequences
- **Positive:** Central policy enforcement, clear separation of concerns.
- **Negative:** Hub Firewall adds ~$290/month (Basic SKU).
- **Follow-up:** Firewall SKU decision → Decision 2.

---

## Decision 2: Azure Firewall Basic SKU over Standard

- **Status:** Accepted
- **Date:** 2026-09-16

### Context
Azure Firewall is required for centralized traffic inspection. Two SKUs are available: Basic and Standard.

### Decision
Use **Basic SKU**.

### Alternatives Considered

| Option | Est. Monthly | Features | Verdict |
|---|---|---|---|
| **Basic** | ~$290 | L3-L4 filtering, threat intel | ✅ Chosen |
| **Standard** | ~$900+ | L7 filtering, FQDN tags, TLS inspection | ❌ Rejected for demo |

### Consequences
- **Positive:** Significant cost saving for a portfolio project.
- **Negative:** No L7 filtering — acceptable for a demo environment.
- **Note:** In production, Standard SKU would be chosen for L7 inspection.

---

## Decision 3: Terraform over Bicep

- **Status:** Accepted
- **Date:** 2026-09-16

### Context
Infrastructure must be deployed as code. Both Terraform and Bicep are viable.

### Decision
Use **Terraform**.

### Alternatives Considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **Terraform** | Multi-cloud, large community, mature modules | State management complexity | ✅ Chosen |
| **Bicep** | Native Azure, no state file | Azure-only, smaller community | ❌ Rejected |

### Consequences
- **Positive:** Transferable skill across clouds, rich module ecosystem.
- **Negative:** Must manage remote state (addressed in Decision 4).

---

## Decision 4: Remote State Backend

- **Status:** Accepted
- **Date:** 2026-09-16

### Context
Terraform state must be stored securely and shared across team members and CI runners.

### Decision
Use **Azure Storage Account** as remote backend.

### Alternatives Considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **Local state** | Zero setup | No team collaboration, risk of loss | ❌ Rejected |
| **Azure Storage** | Built-in locking, versioning, RBAC | Requires bootstrap | ✅ Chosen |
| **Terraform Cloud** | Free tier, UI | External dependency | ❌ Rejected |

### Consequences
- **Positive:** Team-safe, CI-ready, state locking prevents race conditions.
- **Negative:** Requires a one-time `bootstrap.sh` run.