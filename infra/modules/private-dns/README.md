# Module: private-dns

Creates private DNS zones in the Hub and links them to Hub and all Spoke VNets.

## Zones created

| Zone | Used by |
|------|---------|
| `privatelink.postgres.database.azure.com` | PostgreSQL Flexible Server |
| `privatelink.vaultcore.azure.net` | Key Vault Private Endpoint |
| `privatelink.azurewebsites.net` | App Service / Function Private Endpoint |

## Why

When a Private Endpoint is created, it registers an A record in the corresponding private DNS zone. Workloads then resolve the service via this zone instead of the public DNS — all traffic stays on the private network.

## Inputs

| Name | Type | Description |
|------|------|-------------|
| `location` | string | Azure region |
| `tags` | map(string) | Resource tags |
| `hub_resource_group_name` | string | Hub RG name |
| `hub_vnet_id` | string | Hub VNet ID |
| `spoke_vnet_ids` | map(string) | Map of spoke name → VNet ID |
| `private_dns_zones` | list(string) | Zones to create |

## Outputs

| Name | Description |
|------|-------------|
| `zone_ids` | Map of zone name → zone ID |
| `zone_names` | List of zone names |