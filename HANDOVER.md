# Azure Landing Zone Platform Handover Guide

This document serves as the formal operational contract and technical specification between the **Platform/Cloud Engineering Team** (the producers of the Landing Zone) and **Application/Workload Teams** (the consumers building Project 2, 3, 4, etc.).

This foundation provides a multi-tenant, hub-spoke, CAF-aligned environment with centralized security, inspection, DNS resolution, and automated policy guardrails.

---

## 1. Landing Zone Topology & Exported Outputs

The landing zone state is maintained remotely in an encrypted Azure Storage Account. Downstream projects must read exported values using `terraform_remote_state`.

### Core Outputs Reference Table

| Output Attribute | Resource Type / Meaning | Value / Format | Application Usage |
|---|---|---|---|
| `hub_vnet_id` | Core Hub Virtual Network | Resource ID (`/subscriptions/.../vnet-hub`) | Peering custom spoke VNets |
| `hub_resource_group_name` | Hub Network Resource Group | `rg-hub-network` | Bastion host access, NSG flow logs |
| `firewall_private_ip` | Azure Firewall Private IP | `10.0.1.4` | Default gateway (`0.0.0.0/0`) next-hop |
| `spoke_app_resource_group_name` | Compute Resource Group | `rg-spoke-app` | Primary placement for VMs, Web Apps |
| `spoke_data_resource_group_name` | Data Resource Group | `rg-spoke-data` | Placement for Databases, Key Vaults |
| `spoke_app_subnet_ids["app"]` | App Subnet | `10.1.1.0/24` | Application tiers, App Service VNet integration |
| `spoke_app_subnet_ids["func"]` | Function Subnet | `10.1.2.0/24` | Dedicated serverless execution runtimes |
| `spoke_data_subnet_ids["data"]` | Database Subnet | `10.2.1.0/24` | Managed database instances (e.g., PostgreSQL) |
| `spoke_data_subnet_ids["pe"]` | Private Endpoint Subnet | `10.2.2.0/24` | Storage, Key Vault, and Database Private IPs |
| `log_analytics_workspace_id` | Central Log Analytics Workspace | Resource ID (`/subscriptions/.../law-landing-zone`) | Diagnostic Settings for all workloads |
| `private_dns_zone_ids` | Map of Private DNS Zones | Map of Zone Names to Resource IDs | Private Endpoint DNS registration |

---

## 2. Hard Governance Guardrails (Azure Policy Enforcement)

The landing zone enforces strict Azure Policies in **Deny** mode. Workload Terraform templates violating any of these criteria will fail deployment automatically at the Azure Resource Manager (ARM) API layer.

### A. Approved Regions Policy
* **Allowed Regions:** `malaysiawest` and `southeastasia`.
* **Behavior:** Deploying resources to any other location (e.g., `eastus`, `centralus`) throws `RequestDisallowedByPolicy`.

### B. Mandatory Resource Tags Policy
Every resource must contain the following tags (exact case-sensitive keys):

```hcl
tags = {
  CostCenter = "1001"            # Workload billing department code
  Env        = "prod"            # Target environment: dev, staging, prod, shared
  Owner      = "App-Team"        # Responsible engineering team or individual
  Project    = "Project-2-WebApp" # Specific project identifier
}

```

### C. Public IP Ingress Denial Policy

* Workload subnets must never expose public IP addresses (`Microsoft.Network/publicIPAddresses`).
* Exception: Resources explicitly tagged with `Env = "shared"` within dedicated perimeter segments.
* All incoming and outgoing network traffic must traverse the central Azure Firewall or Azure Bastion.

---

## 3. Workload Integration Contract (Producer-Consumer Pattern)

Downstream Terraform repositories (such as Project 2: Multi-Tier Web Application) connect into this foundation without modifying the core landing zone code.

### Sample Integration Block (`data.tf`)

```hcl
data "terraform_remote_state" "landing_zone" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstaterajim01"
    container_name       = "tfstate"
    key                  = "landing-zone.tfstate"
  }
}

locals {
  app_rg_name        = data.terraform_remote_state.landing_zone.outputs.spoke_app_resource_group_name
  data_rg_name       = data.terraform_remote_state.landing_zone.outputs.spoke_data_resource_group_name
  app_subnet_id      = data.terraform_remote_state.landing_zone.outputs.spoke_app_subnet_ids["app"]
  data_subnet_id     = data.terraform_remote_state.landing_zone.outputs.spoke_data_subnet_ids["data"]
  pe_subnet_id       = data.terraform_remote_state.landing_zone.outputs.spoke_data_subnet_ids["pe"]
  central_law_id     = data.terraform_remote_state.landing_zone.outputs.log_analytics_workspace_id
  firewall_egress_ip = data.terraform_remote_state.landing_zone.outputs.firewall_private_ip
}

```

---

## 4. Private DNS & Endpoint Routing Resolution

The landing zone maintains three centralized Hub Private DNS Zones linked across all spokes:

1. `privatelink.postgres.database.azure.com`
2. `privatelink.vaultcore.azure.net`
3. `privatelink.azurewebsites.net`

### Private Endpoint Placement Rules

* Deploy Private Endpoints exclusively into `PrivateEndpointSubnet` (`10.2.2.0/24`).
* Set `private_dns_zone_group` to link directly into the respective Hub DNS zone ID exported from the remote state.
* Do **not** deploy duplicate Private DNS Zones inside application resource groups.

---

## 5. Security Posture & Least-Privilege Identity (RBAC)

Access boundaries are restricted via Entra ID groups and custom roles:

* **Platform Administrators (`network-admins`):** Manage central hub networking, firewall rules, and policy definitions.
* **Workload Engineers (`cloud-engineers`):** Possess `Contributor` rights restricted strictly to `rg-spoke-app` and `rg-spoke-data`. Cannot modify peering, route tables, or hub firewalls.
* **Security Auditors (`security-auditors`):** Read-only visibility across the subscription with explicit Network Watcher and Bastion diagnostic review privileges.

---

## 6. Onboarding Checklist for Workload Teams

Before deploying Project 2 or subsequent applications, teams must complete this checklist:

* [ ] Terraform remote backend credentials configured targeting `rg-tfstate/sttfstaterajim01`.
* [ ] Codebase validated using `validate-tags.ps1` to prevent deployment rejection.
* [ ] Virtual machines and app instances configured without public IPs.
* [ ] Diagnostic settings wired to stream metrics and audit logs directly to `law-landing-zone`.
* [ ] Workload budget alerts established with notification thresholds set at 80% and 100%.

```

```