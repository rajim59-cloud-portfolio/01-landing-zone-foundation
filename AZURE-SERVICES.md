# Azure Landing Zone Foundation — Resource Catalog & BOM

This document serves as the exhaustive **Bill of Materials (BOM)** and technical component inventory for the Azure Landing Zone Foundation (`malaysiawest`). It catalogs every Azure platform service, resource type, SKU tier, and operational role codified within this repository.

---

## 1. Executive Summary: Implemented Domains

| Architectural Domain | Primary Microsoft Azure Services Utilized | Core Purpose |
|---|---|---|
| **Networking & Perimeter** | Azure Virtual Network, Azure Firewall, Route Tables (UDR), VNet Peering | Centralized hub-spoke isolation, zero public IP surface, and forced egress inspection. |
| **Secure Management** | Azure Bastion | Zero-trust private administrative access without internet-exposed ports. |
| **Private DNS Resolution**| Azure Private DNS Zones, Virtual Network Links | Deterministic cross-spoke name resolution for private endpoints without split-brain DNS. |
| **Identity & Access (RBAC)**| Microsoft Entra ID (Groups), Custom Azure Roles, Role Assignments | Least-privilege operational scoping separating Platform from Workload teams. |
| **Governance & Policy** | Azure Policy Definitions, Policy Assignments | Declarative enforcement of tagging, geographic boundary, and public IP denial. |
| **Observability & Logging** | Azure Log Analytics Workspace, Diagnostic Settings, KQL | Centralized telemetry collection, firewall egress logging, and operational querying. |
| **FinOps & Cost Control** | Azure Consumption Budgets, Action Groups, Ephemeral Automation | Proactive spending notifications and automated destruction to maintain a $0.00 idle rate. |
| **Security Posture (CSPM)**| Microsoft Defender for Cloud (Free Tier), Security Contact | Continuous Microsoft Cloud Security Benchmark (MCSB) auditing without paid licensing drift. |
| **Vending & Workloads** | Azure Verified Module (AVM) Vending Pattern, Managed Disks, VMs | Downstream workload provisioning simulation and integration validation. |

---

## 2. Granular Resource Inventory by Category

### A. Networking & Perimeter Security

| Azure Resource Type (`Provider Namespace`) | Resource Instance Name | SKU / Sizing | Logical Subnet / Scope | Purpose & Configuration |
|---|---|---|---|---|
| `Microsoft.Network/virtualNetworks` | `vnet-hub` | `/16` (`10.0.0.0/16`) | Core Hub | Central platform mesh and security perimeter. |
| `Microsoft.Network/virtualNetworks` | `vnet-spoke-app` | `/16` (`10.1.0.0/16`) | Compute Spoke | Primary hosting tier for compute/app runtimes. |
| `Microsoft.Network/virtualNetworks` | `vnet-spoke-data`| `/16` (`10.2.0.0/16`) | Data Spoke | Tier for persistence, private endpoints, and databases. |
| `Microsoft.Network/virtualNetworks/subnets` | `AzureFirewallSubnet` | `/26` (`10.0.1.0/26`) | `vnet-hub` | Dedicated subnet for Azure Firewall private IP. |
| `Microsoft.Network/virtualNetworks/subnets` | `AzureFirewallManagementSubnet` | `/26` (`10.0.5.0/26`) | `vnet-hub` | Dedicated operational subnet for Firewall Basic SKU. |
| `Microsoft.Network/virtualNetworks/subnets` | `AzureBastionSubnet` | `/26` (`10.0.2.0/26`) | `vnet-hub` | Dedicated bastion ingress jump-host subnet. |
| `Microsoft.Network/virtualNetworks/subnets` | `AppSubnet` | `/24` (`10.1.1.0/24`) | `vnet-spoke-app` | Compute subnet delegated to `Microsoft.Web/serverFarms`. |
| `Microsoft.Network/virtualNetworks/subnets` | `FunctionSubnet` | `/24` (`10.1.2.0/24`) | `vnet-spoke-app` | Serverless runtime subnet delegated to serverFarms. |
| `Microsoft.Network/virtualNetworks/subnets` | `DataSubnet` | `/24` (`10.2.1.0/24`) | `vnet-spoke-data` | Delegated to `Microsoft.DBforPostgreSQL/flexibleServers`. |
| `Microsoft.Network/virtualNetworks/subnets` | `PrivateEndpointSubnet` | `/24` (`10.2.2.0/24`) | `vnet-spoke-data` | Dedicated subnet for Private IP Endpoints. |
| `Microsoft.Network/azureFirewalls` | `afw-hub` | **Basic SKU** | `AzureFirewallSubnet` | Stateful L3/L4 filtering, threat intel alert, private IP `10.0.1.4`. |
| `Microsoft.Network/bastionHosts` | `bastion-hub` | **Basic SKU** | `AzureBastionSubnet` | Browser-based RDP/SSH tunnel without public IP exposure. |
| `Microsoft.Network/routeTables` | `rt-spoke-app` | User-Defined (UDR) | Attached to App subnets | Forces `0.0.0.0/0` and `10.2.0.0/16` next-hop to `10.0.1.4`. |
| `Microsoft.Network/routeTables` | `rt-spoke-data`| User-Defined (UDR) | Attached to Data subnets | Forces `0.0.0.0/0` and `10.1.0.0/16` next-hop to `10.0.1.4`. |
| `Microsoft.Network/networkSecurityGroups` | `nsg-spoke-app` | Standard L4 Rules | `AppSubnet` | Ingress filtering, port 22/443 restriction, deny direct internet. |
| `Microsoft.Network/virtualNetworkPeerings` | 4 × Peering Links | Bidirectional Mesh | Hub ↔ Spokes | Interconnects spokes to hub with gateway transit disabled. |
| `Microsoft.Network/publicIPAddresses` | 3 × Standard PIPs | Standard (Static) | `rg-hub-network` | Assigned to Firewall (2×) and Bastion (1×) per Azure requirements. |

---

### B. Private DNS & Resolution Infrastructure

| Azure Resource Type | Zone Name / Instance | Linked Virtual Networks | Target Azure Private Endpoint Services |
|---|---|---|---|
| `Microsoft.Network/privateDnsZones` | `privatelink.postgres.database.azure.com` | `vnet-hub`, `vnet-spoke-app`, `vnet-spoke-data` | Azure PostgreSQL Flexible Server private IP binding. |
| `Microsoft.Network/privateDnsZones` | `privatelink.vaultcore.azure.net` | `vnet-hub`, `vnet-spoke-app`, `vnet-spoke-data` | Azure Key Vault cryptographic & secrets access. |
| `Microsoft.Network/privateDnsZones` | `privatelink.azurewebsites.net` | `vnet-hub`, `vnet-spoke-app`, `vnet-spoke-data` | Azure App Service / Function Apps private endpoints. |
| `Microsoft.Network/privateDnsZones/virtualNetworkLinks` | 9 × Virtual Network Links | Hub & Spoke VNets | Auto-registration disabled; centralized query resolution. |

---

### C. Governance, Policy & Organizational Hierarchy

| Resource / Entity | Scope / Level | Enforcement Mode | Validation Rule / Criteria |
|---|---|:---:|---|
| **Management Groups (HCL Model)** | `Tenant Root` → `Platform` / `Workloads` / `Sandbox` | Organizational | Codified CAF hierarchy isolating platform from app tenants. |
| `Microsoft.Authorization/policyDefinitions` | `require-tags` | Custom HCL Definition | Checks presence of `CostCenter`, `Env`, `Owner`, `Project`. |
| `Microsoft.Authorization/policyDefinitions` | `allowed-locations` | Custom HCL Definition | Restricts deployment to `malaysiawest` and `southeastasia`. |
| `Microsoft.Authorization/policyDefinitions` | `deny-public-ip` | Custom HCL Definition | Blocks `Microsoft.Network/publicIPAddresses` (unless tagged `Env=shared`). |
| `Microsoft.Authorization/policyAssignments` | Subscription Scope | **Deny Mode** | Immediately rejects non-compliant ARM API calls at deployment time. |

---

### D. Identity, Security & Entra ID RBAC

| Security Entity / Group Name | Provider Namespace | Assigned Role | Access Scope | Purpose |
|---|---|---|---|---|
| `network-admins` | `Microsoft.Graph/groups` | `Network Contributor` | `rg-hub-network` | Administer firewall rules, route tables, and peerings. |
| `cloud-engineers` | `Microsoft.Graph/groups` | `Contributor` | `rg-spoke-app`, `rg-spoke-data` | Application workload deployment (cannot alter hub rules). |
| `security-auditors` | `Microsoft.Graph/groups` | `Reader` + Network Watcher | Subscription Root | Read-only compliance review, diagnostic log inspection. |

---

### E. Monitoring, Telemetry & Posture Management

| Azure Resource Type | Resource Instance Name | SKU / Tier | Details & Capabilities |
|---|---|---|---|
| `Microsoft.OperationalInsights/workspaces` | `law-landing-zone` | Pay-as-you-go | Centralized Log Analytics; 30-day retention; diagnostic sink. |
| `Microsoft.Insights/diagnosticSettings` | Central Diagnostic Links | Telemetry Stream | Streams Firewall metrics, NSG flow logs, and Bastion audit trails. |
| `Microsoft.Security/pricings` | `CloudPosture` | **Free Tier** | Foundational CSPM evaluating continuous MCSB benchmarks. |
| `Microsoft.Security/securityContacts` | `default` | Alert Contact | Automated alerting for high-severity security incidents. |

---

### F. FinOps, Budgets & Storage Backend

| Resource / Tool | Resource Instance Name | Pricing Strategy | Guardrail Function |
|---|---|---|---|
| `Microsoft.Consumption/budgets` | `budget-landing-zone` | $20.00 / month | Triggers alert emails via Action Group at 80% ($16) and 100% ($20). |
| `Microsoft.Insights/actionGroups` | `ag-email-alerts` | Free / Pay-Per-Alert | Notification routing to designated platform engineering emails. |
| `Microsoft.Storage/storageAccounts` | `sttfstaterajim01` | Standard LRS Hot | Hosts encrypted remote Terraform state blob and concurrency leases. |
| `Windows PowerShell Automation` | `validate-tags.ps1` | Native Scripting | Pre-flight validation gate blocking untagged infrastructure before `terraform apply`. |
| `Windows PowerShell Automation` | `destroy.ps1` | Native Scripting | Cleans all billable resources to guarantee a verified **$0.00** idle run-rate. |

---

## 3. Downstream Handover Output Matrix

The resources above export the following contract variables into `landing-zone.tfstate`, consumed directly by **Project 2+** via `terraform_remote_state`:

```text
Exports:
├── hub_vnet_id
├── firewall_private_ip (10.0.1.4)
├── spoke_app_subnet_ids (app, func)
├── spoke_data_subnet_ids (data, pe)
├── log_analytics_workspace_id
└── private_dns_zone_ids (postgres, vault, websites)