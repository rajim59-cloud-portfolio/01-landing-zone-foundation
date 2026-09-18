# Architecture

This document describes the Management Group governance hierarchy, Hub-Spoke network topology, CIDR allocation, peering model, routing strategy, and subscription vending patterns deployed by this Azure Landing Zone Foundation.

---

## 1. High-Level Topology


```

┌────────────────────────────────────────────────────────┐
│                        Hub VNet                        │
│                      10.0.0.0/16                       │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ AzureFirewallSubnet          10.0.1.0/26         │  │
│  │ AzureFirewallManagementSubnet 10.0.5.0/26        │  │
│  │ AzureBastionSubnet           10.0.2.0/26         │  │
│  │ GatewaySubnet                10.0.3.0/27         │  │
│  │ SharedServicesSubnet         10.0.4.0/24         │  │
│  └──────────────────────────────────────────────────┘  │
└───────────────────────────┬────────────────────────────┘
│
┌───────────────┴───────────────┐
│                               │
┌───────────▼───────────┐       ┌───────────▼───────────┐
│       Spoke: App      │       │      Spoke: Data      │
│      10.1.0.0/16      │       │      10.2.0.0/16      │
│                       │       │                       │
│ AppSubnet             │       │ DataSubnet            │
│ 10.1.1.0/24           │       │ 10.2.1.0/24           │
│                       │       │                       │
│ FunctionSubnet        │       │ PrivateEndpointSubnet │
│ 10.1.2.0/24           │       │ 10.2.2.0/24           │
└───────────────────────┘       └───────────────────────┘

```

---

## 2. CIDR Allocation Plan

| VNet / Subnet | CIDR | Purpose | Delegation |
|---|---|---|---|
| **Hub VNet** | `10.0.0.0/16` | Central platform hub & perimeter inspection | — |
| AzureFirewallSubnet | `10.0.1.0/26` | Central Azure Firewall (Basic SKU) | — |
| AzureFirewallManagementSubnet | `10.0.5.0/26` | Firewall management & operational traffic | — |
| AzureBastionSubnet | `10.0.2.0/26` | Azure Bastion (Basic SKU) for private admin | — |
| GatewaySubnet | `10.0.3.0/27` | Reserved for future S2S VPN or ExpressRoute | — |
| SharedServicesSubnet | `10.0.4.0/24` | Central tooling, agents, private DNS resolvers | — |
| **Spoke-App VNet** | `10.1.0.0/16` | Application & compute tier workload | — |
| AppSubnet | `10.1.1.0/24` | Container Apps, App Service VNet integration | `Microsoft.Web/serverFarms` |
| FunctionSubnet | `10.1.2.0/24` | Serverless runtime execution | `Microsoft.Web/serverFarms` |
| **Spoke-Data VNet** | `10.2.0.0/16` | Data persistence & secure endpoints | — |
| DataSubnet | `10.2.1.0/24` | PostgreSQL Flexible Server instances | `Microsoft.DBforPostgreSQL/flexibleServers` |
| PrivateEndpointSubnet | `10.2.2.0/24` | Private Endpoints (Key Vault, SQL, Storage) | — |

---

## 3. VNet Peering Model

| Source VNet | Target VNet | Type | Gateway Transit | Traffic Flow |
|---|---|---|:---:|---|
| Hub VNet | Spoke-App | Bidirectional | Disabled | Forwarded traffic allowed |
| Hub VNet | Spoke-Data | Bidirectional | Disabled | Forwarded traffic allowed |
| Spoke-App | Spoke-Data | **None** | — | **Blocked directly.** Inter-spoke traffic hops through Firewall (`10.0.1.4`) |

---

## 4. Route Tables (Deterministic Egress)

Centralized egress inspection is enforced via User-Defined Routes (UDR), overriding default Azure routing to prevent Longest Prefix Match (LPM) bypasses.

### Spoke-App Route Table (`rt-spoke-app`)

| Route Name | Address Prefix | Next Hop Type | Next Hop IP | Purpose |
|---|---|---|---|---|
| `to-firewall` | `0.0.0.0/0` | VirtualAppliance | `10.0.1.4` | Default egress to central firewall |
| `to-spoke-data` | `10.2.0.0/16` | VirtualAppliance | `10.0.1.4` | Inter-spoke inspection to data tier |

### Spoke-Data Route Table (`rt-spoke-data`)

| Route Name | Address Prefix | Next Hop Type | Next Hop IP | Purpose |
|---|---|---|---|---|
| `to-firewall` | `0.0.0.0/0` | VirtualAppliance | `10.0.1.4` | Default egress to central firewall |
| `to-spoke-app` | `10.1.0.0/16` | VirtualAppliance | `10.0.1.4` | Inter-spoke inspection to app tier |

---

## 5. Network Security Groups (NSGs)

NSGs act as the second layer of defense (defense-in-depth), protecting subnets from lateral traversal.

### App Subnet NSG Rules (`nsg-spoke-app`)

| Priority | Rule Name | Direction | Source | Destination | Port | Action |
|---|---|---|---|---|---|:---:|
| 100 | `AllowHubInbound` | Inbound | `10.0.0.0/16` | Subnet CIDR | 443 | Allow |
| 110 | `AllowBastionSSH` | Inbound | `10.0.2.0/26` | Subnet CIDR | 22 | Allow |
| 200 | `DenyDirectInternet`| Inbound | Internet | Subnet CIDR | Any | Deny |
| 300 | `AllowHubOutbound` | Outbound | Subnet CIDR | `10.0.0.0/16` | Any | Allow |
| 400 | `AllowInternetEgress`| Outbound | Subnet CIDR | Internet | 443 | Allow |
| 500 | `DenyAllOutbound` | Outbound | Any | Any | Any | Deny |

---

## 6. Centralized Private DNS Resolution

Private DNS Zones are consolidated in the central Hub resource group (`rg-hub-network`) to eliminate multi-tenant split-brain DNS resolution and duplicate records.


```

```
              ┌─────────────────────────────────────────┐
              │          Hub Private DNS Zones          │
              │  - privatelink.postgres.database...     │
              │  - privatelink.vaultcore.azure.net      │
              │  - privatelink.azurewebsites.net        │
              └─────────────┬───────────────────────────┘
                            │ Virtual Network Links
   ┌────────────────────────┼────────────────────────┐
   │                        │                        │

```

┌──────▼──────┐          ┌──────▼──────┐          ┌──────▼──────┐
│  vnet-hub   │          │vnet-spoke-app│         │vnet-spoke-data
└─────────────┘          └─────────────┘          └─────────────┘

```

| Private DNS Zone | Target Azure Service | Linked VNets |
|---|---|---|
| `privatelink.postgres.database.azure.com` | Azure Database for PostgreSQL Flexible Server | Hub, Spoke-App, Spoke-Data |
| `privatelink.vaultcore.azure.net` | Azure Key Vault Private Endpoints | Hub, Spoke-App, Spoke-Data |
| `privatelink.azurewebsites.net` | Azure App Service / Function Apps Private Endpoints | Hub, Spoke-App, Spoke-Data |

---

## 7. Management Group Hierarchy (CAF Alignment)

The governance boundary is structured to ensure policy inheritance across all present and future enterprise workload subscriptions:


```

Tenant Root Group
├── Platform
│   ├── Identity (Central Entra ID sync & governance)
│   ├── Management (Central Log Analytics & Defender monitoring)
│   └── Connectivity (Hub VNet, Firewall, and Bastion - Current Scope)
├── Workloads
│   ├── Production (Downstream production applications, e.g., Project 2)
│   └── NonProduction (Development & QA sandboxes)
└── Sandbox (Ephemeral, policy-exempt development environments)

```

**Inheritance Mechanics:** Azure Policies assigned at the `Workloads` management group level (`allowed-locations`, `require-tags`, `deny-public-ip`) are automatically inherited by any newly provisioned child subscription without manual intervention.

---

## 8. Subscription Vending Pattern (AVM-Aligned)

To programmatic onboarding of downstream applications, the landing zone implements the Azure Verified Modules (AVM) subscription vending flow:


```

Platform Engineering                             Workload / Product Team
│                                                   │
│ 1. Request Workload Landing Zone                  │
│◄──────────────────────────────────────────────────│
│                                                   │
│ 2. Run subscription-vending Module                │
│    - Provision / Associate Sub to Workloads MG    │
│    - Deploy Spoke VNet (Dedicated CIDR)           │
│    - Configure Bidirectional Hub Peering          │
│    - Deploy UDR Routing to 10.0.1.4 (Firewall)    │
│    - Establish Workload Consumption Budget        │
│                                                   │
│ 3. Export Remote State & Credentials              │
│──────────────────────────────────────────────────►│
│                                                   │
│                                                   │ 4. Deploy Application
│                                                   │    (Policy Guardrails Enforced)

```

---

## 9. References

- [Microsoft CAF: Network topology and connectivity](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/network-topology-and-connectivity)
- [Microsoft CAF: Management group and subscription organization](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/management-group-and-subscription-organization)
- [Azure Verified Modules (AVM) for Subscription Vending](https://github.com/Azure/terraform-azurerm-avm-ptn-alz-sub-vending)
