# Module: identity

Provisions Entra ID groups and least-privilege RBAC assignments.

## Groups

| Group | Scope | Role |
|-------|-------|------|
| `cloud-engineers` | Spoke-App, Spoke-Data RGs | Contributor |
| `network-admins` | Hub RG | Network Contributor |
| `security-auditors` | Subscription | Reader |

## Custom Role

- **VNet-Reader** — `Microsoft.Network/virtualNetworks/read`, `.../subnets/read`, `.../peerings/read`, `networkSecurityGroups/read`, `routeTables/read`.

## Inputs

| Name | Type | Description |
|------|------|-------------|
| `tenant_id` | string | Azure AD tenant ID |
| `subscription_id` | string | Subscription ID |
| `hub_resource_group_name` | string | Hub RG name |
| `spoke_app_resource_group_name` | string | Spoke App RG name |
| `spoke_data_resource_group_name` | string | Spoke Data RG name |

## Outputs

| Name | Description |
|------|-------------|
| `cloud_engineers_group_id` | Object ID of `cloud-engineers` |
| `security_auditors_group_id` | Object ID of `security-auditors` |
| `network_admins_group_id` | Object ID of `network-admins` |
| `vnet_reader_role_id` | Custom VNet-Reader role ID |