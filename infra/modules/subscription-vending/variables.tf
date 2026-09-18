variable "subscription_id" {
  description = "Target subscription ID"
  type        = string
}

variable "workload_name" {
  description = "Workload identifier (e.g. customer-handling)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "malaysiawest"
}

variable "tags" {
  description = "Required tags enforced by Azure Policy"
  type = object({
    CostCenter = string
    Env        = string
    Owner      = string
    Project    = string
  })
}

variable "management_group_id" {
  description = "Target Management Group ID"
  type        = string
}

variable "hub_vnet_id" {
  description = "Hub VNet ID for peering"
  type        = string
}

variable "hub_vnet_name" {
  description = "Hub VNet name"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Hub resource group name"
  type        = string
}

variable "hub_vnet_cidr" {
  description = "Hub VNet CIDR"
  type        = string
}

variable "firewall_private_ip" {
  description = "Firewall private IP for default egress"
  type        = string
}

variable "bastion_subnet_cidr" {
  description = "Bastion subnet CIDR"
  type        = string
}

variable "workload_vnet_cidr" {
  description = "Spoke VNet CIDR for this workload"
  type        = string
}

variable "create_budget" {
  description = "Create a budget for this workload"
  type        = bool
  default     = true
}

variable "budget_amount_usd" {
  description = "Monthly budget in USD"
  type        = number
  default     = 20
}

variable "alert_email" {
  description = "Email for budget notifications"
  type        = string
}