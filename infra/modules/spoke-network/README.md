# Module: spoke-network

Provisions a Spoke VNet peered to the Hub, with NSG, route table (all traffic through Firewall), and supporting subnets.

**This module is reusable** — pass a different `name` and `vnet_cidr` to create N spokes.

## What it creates

| Resource | Naming pattern | Purpose |
|----------|---------------|---------|
| Resource Group | `rg-spoke-<name>` | Container |
| Virtual Network | `vnet-spoke-<name>` | Spoke VNet |
| Subnets | (per `var.subnets`) | Workload subnets |
| NSG | `nsg-spoke-<name>` | Inbound/outbound rules |
| Route Table | `rt-spoke-<name>` | Force 0.0.0.0/0 → Firewall |
| Peering (out) | `peer-<name>-to-hub` | Spoke → Hub |
| Peering (in) | `peer-hub-to-<name>` | Hub → Spoke |

## Inputs

| Name | Type | Description |
|------|------|-------------|
| `name` | string | Spoke identifier (e.g., `app`, `data`) |
| `location` | string | Azure region |
| `tags` | map(string) | Tags |
| `vnet_cidr` | string | Spoke VNet address space |
| `subnets` | map(object) | Subnets: `{ key = { name, address_prefix } }` |
| `hub_vnet_id` | string | Hub VNet ID |
| `hub_vnet_name` | string | Hub VNet name |
| `hub_resource_group_name` | string | Hub RG name |
| `hub_vnet_cidr` | string | Hub CIDR (for NSG) |
| `firewall_private_ip` | string | Firewall IP (for routing) |
| `bastion_subnet_cidr` | string | Bastion CIDR (for SSH rule) |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Spoke RG name |
| `vnet_id` | Spoke VNet ID |
| `vnet_name` | Spoke VNet name |
| `subnet_ids` | Map of `subnet_key → subnet_id` |

## NSG Rules

| Priority | Direction | Source | Port | Action |
|----------|-----------|--------|------|--------|
| 100 | Inbound | Hub VNet CIDR | Any | Allow |
| 110 | Inbound | Bastion subnet | 22 | Allow |
| 200 | Inbound | Internet | Any | Deny |

## Routing

All outbound traffic (`0.0.0.0/0`) is routed to the Firewall's private IP via a user-defined route. This ensures every packet leaving the spoke is inspected.