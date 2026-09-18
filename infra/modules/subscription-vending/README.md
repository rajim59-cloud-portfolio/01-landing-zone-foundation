```markdown
# Module: subscription-vending (Simulated)

Simulates the enterprise subscription vending pattern — where a central platform team programmatically provisions and vends a fully configured, compliant subscription to an application team.

## Real-World Flow (Azure Verified Modules - AVM)

The standard Azure Verified Module (`Azure/avm-ptn-alz-sub-vending/azure`) executes the following operations:

1. Provisions a new subscription via `azurerm_subscription`
2. Places the subscription into the targeted Management Group hierarchy to automatically inherit Azure Policies
3. Provisions a dedicated workload virtual network (VNet) and configures bidirectional peering to the Hub VNet
4. Grants workload-specific least-privilege Role-Based Access Control (RBAC) to application teams
5. Configures cost management budgets and automated notification thresholds
6. Configures workload identity federation (e.g., GitHub Actions OIDC or Terraform Cloud)

## Simulation Design

To eliminate multi-subscription provisioning overhead while validating the design, all resources are deployed within the existing subscription boundary.

| Step | Real AVM Pattern | Simulation Implementation |
|------|------------------|---------------------------|
| 1. Subscription Provisioning | Creates standalone subscription | Reuses existing subscription boundary |
| 2. Management Group Alignment | Direct MG subscription association | Documented architecture pattern |
| 3. Network Architecture | Dedicated VNet + Hub peering | Full VNet provisioning + bidirectional Hub peering |
| 4. Governance & RBAC | Sub-scoped RBAC assignments | Inherited platform policy guardrails |
| 5. Cost Management | Subscription-scoped budget | Resource group-scoped consumption budget |
| 6. CI/CD Federation | Federated workload credentials | Detailed handover specifications |

## Example Usage

```hcl
module "customer_handling_workload" {
  source = "./modules/subscription-vending"

  workload_name           = "customer-handling"
  subscription_id         = var.subscription_id
  location                = var.location
  tags                    = var.tags
  management_group_id     = module.management_groups.workloads_prod_mg_id
  workload_vnet_cidr      = "10.10.0.0/16"
  hub_vnet_id             = module.hub_network.hub_vnet_id
  hub_vnet_name           = module.hub_network.hub_vnet_name
  hub_resource_group_name = module.hub_network.resource_group_name
  hub_vnet_cidr           = var.hub_vnet_cidr
  firewall_private_ip     = module.hub_network.firewall_private_ip
  bastion_subnet_cidr     = "10.0.2.0/26"
  alert_email             = var.alert_email
}

```

## Inputs / Outputs

Refer to `variables.tf` for configuration parameters and `outputs.tf` for exported resource identifiers.

```

```