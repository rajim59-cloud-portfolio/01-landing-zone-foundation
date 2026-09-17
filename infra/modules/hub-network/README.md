# Module: hub-network

Provisions the Hub VNet with shared platform services (Azure Firewall, Azure Bastion, Gateway subnet).

## What it creates

| Resource | Name | Purpose |
|----------|------|---------|
| Resource Group | `rg-hub-network` | Container for all hub resources |
| Virtual Network | `vnet-hub` | 10.0.0.0/16 |
| Subnet | `AzureFirewallSubnet` | 10.0.1.0/26 — required name |
| Subnet | `AzureBastionSubnet` | 10.0.2.0/26 — required name |
| Subnet | `GatewaySubnet` | 10.0.3.0/27 — reserved |
| Subnet | `SharedServicesSubnet` | 10.0.4.0/24 |
| Public IP | `pip-fw-hub` | Firewall egress IP |
| Firewall Policy | `afwp-hub-basic` | Required for Basic SKU |
| Firewall | `afw-hub` | Basic SKU |
| Public IP | `pip-bastion-hub` | Bastion public IP |
| Bastion Host | `bastion-hub` | Basic SKU |

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `location` | string | — | Azure region |
| `tags` | map(string) | — | Tags for all resources |
| `hub_vnet_cidr` | string | `10.0.0.0/16` | Hub VNet address space |
| `firewall_subnet_cidr` | string | `10.0.1.0/26` | Firewall subnet |
| `bastion_subnet_cidr` | string | `10.0.2.0/26` | Bastion subnet |
| `gateway_subnet_cidr` | string | `10.0.3.0/27` | Gateway subnet |
| `shared_services_subnet_cidr` | string | `10.0.4.0/24` | Shared services subnet |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Hub RG name |
| `hub_vnet_id` | Hub VNet resource ID |
| `hub_vnet_name` | Hub VNet name |
| `firewall_private_ip` | Firewall private IP (e.g., 10.0.1.4) |
| `bastion_subnet_cidr` | Bastion subnet CIDR |

## Notes

- **Basic SKU Firewall requires a Firewall Policy** — this module provisions one.
- The `AzureFirewallSubnet` and `AzureBastionSubnet` names are **reserved by Azure** and cannot be changed.
- GatewaySubnet is reserved for future VPN/ExpressRoute — no resources deployed yet.