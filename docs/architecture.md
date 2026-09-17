# Architecture

This document describes the Hub-Spoke network topology, CIDR allocation, peering model, and routing strategy deployed by this project.

---

## 1. High-Level Topology

┌──────────────────────────────────────┐
│ Hub VNet │
│ 10.0.0.0/16 │
│ │
│ ┌────────────────────────────────┐ │
│ │ AzureFirewallSubnet 10.0.1.0/26│ │
│ │ AzureBastionSubnet 10.0.2.0/26│ │
│ │ GatewaySubnet 10.0.3.0/27│ │
│ │ SharedServicesSubnet 10.0.4.0/24│ │
│ └────────────────────────────────┘ │
└───────────┬──────────────────────────┘
│
┌───────────────────┴───────────────────┐
│ │
┌──────────▼──────────┐ ┌───────────▼──────────┐
│ Spoke: App │ │ Spoke: Data │
│ 10.1.0.0/16 │ │ 10.2.0.0/16 │
│ │ │ │
│ AppSubnet │ │ DataSubnet │
│ 10.1.1.0/24 │ │ 10.2.1.0/24 │
│ │ │ │
│ FunctionSubnet │ │ PrivateEndpointSubnet│
│ 10.1.2.0/24 │ │ 10.2.2.0/24 │
└─────────────────────┘ └──────────────────────┘

---

## 2. CIDR Allocation Plan

| VNet / Subnet | CIDR | Purpose | Delegation |
|---|---|---|---|
| Hub VNet | `10.0.0.0/16` | Shared platform services | — |
| AzureFirewallSubnet | `10.0.1.0/26` | Azure Firewall (Basic SKU) | — |
| AzureBastionSubnet | `10.0.2.0/26` | Azure Bastion (Basic SKU) | — |
| GatewaySubnet | `10.0.3.0/27` | Reserved for future VPN/ER | — |
| SharedServicesSubnet | `10.0.4.0/24` | DNS, monitoring agents | — |
| Spoke-App VNet | `10.1.0.0/16` | Workload: application tier | — |
| AppSubnet | `10.1.1.0/24` | App Service / Container Apps | `Microsoft.Web/serverFarms` |
| FunctionSubnet | `10.1.2.0/24` | Azure Functions | `Microsoft.Web/serverFarms` |
| Spoke-Data VNet | `10.2.0.0/16` | Workload: data tier | — |
| DataSubnet | `10.2.1.0/24` | PostgreSQL Flexible Server | `Microsoft.DBforPostgreSQL/flexibleServers` |
| PrivateEndpointSubnet | `10.2.2.0/24` | Private Endpoints | — |

**Why `/16` for VNets and `/24` for subnets:** This gives room for 256 addresses per subnet — enough for autoscaling workloads — while keeping the overall address space manageable.

---

## 3. VNet Peering Model

| From | To | Direction | Purpose |
|---|---|---|---|
| Spoke-App | Hub | Bidirectional | Access Firewall, Bastion, DNS |
| Spoke-Data | Hub | Bidirectional | Access Firewall, Private DNS |
| Spoke-App | Spoke-Data | ❌ None | Traffic must flow through Firewall |

**Key principle:** Spokes do **not** peer directly with each other. All inter-spoke traffic traverses the Hub Firewall for inspection.

---

## 4. Route Tables

### Spoke-App Route Table (`rt-spoke-app`)

| Name | Address Prefix | Next Hop Type | Next Hop IP |
|---|---|---|---|
| `to-firewall` | `0.0.0.0/0` | VirtualAppliance | `10.0.1.4` (Firewall private IP) |
| `to-hub` | `10.0.0.0/16` | VNetPeering | — |
| `to-data` | `10.2.0.0/16` | VirtualAppliance | `10.0.1.4` |

### Spoke-Data Route Table (`rt-spoke-data`)

| Name | Address Prefix | Next Hop Type | Next Hop IP |
|---|---|---|---|
| `to-firewall` | `0.0.0.0/0` | VirtualAppliance | `10.0.1.4` |
| `to-hub` | `10.0.0.0/16` | VNetPeering | — |
| `to-app` | `10.1.0.0/16` | VirtualAppliance | `10.0.1.4` |

---

## 5. Network Security Groups (NSGs)

### NSG on AppSubnet

| Priority | Name | Direction | Source | Destination | Port | Action |
|---|---|---|---|---|---|---|
| 100 | AllowHubInbound | Inbound | `10.0.0.0/16` | Any | 443 | Allow |
| 110 | AllowBastionSSH | Inbound | `10.0.2.0/26` | Any | 22 | Allow |
| 200 | DenyInternetInbound | Inbound | Internet | Any | Any | Deny |
| 300 | AllowHubOutbound | Outbound | Any | `10.0.0.0/16` | Any | Allow |
| 400 | AllowInternetOutbound | Outbound | Any | Internet | 443 | Allow |
| 500 | DenyAllOutbound | Outbound | Any | Any | Any | Deny |

---

## 6. DNS Strategy

- **Private DNS Zones** deployed in Hub, linked to all Spoke VNets.
- Zones: `privatelink.postgres.database.azure.com`, `privatelink.azurewebsites.net`, `privatelink.vaultcore.azure.net`.
- Workloads resolve private endpoints via Hub-linked DNS zones.

---

## 7. Reference

- [Microsoft CAF: Network topology](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/network-topology-and-connectivity)
- [Azure Hub-Spoke best practices](https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)