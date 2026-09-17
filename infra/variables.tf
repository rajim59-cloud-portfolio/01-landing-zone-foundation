# ─── Subscription & Location ──────────────────────────────────────
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

# ─── Tags (enforced by Azure Policy) ──────────────────────────────
variable "tags" {
  description = "Required tags for all resources"
  type = object({
    CostCenter = string
    Env        = string
    Owner      = string
    Project    = string
  })
}

# ─── Networking ───────────────────────────────────────────────────
variable "hub_vnet_cidr" {
  description = "CIDR block for Hub VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "spoke_app_vnet_cidr" {
  description = "CIDR block for Spoke-App VNet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "spoke_data_vnet_cidr" {
  description = "CIDR block for Spoke-Data VNet"
  type        = string
  default     = "10.2.0.0/16"
}

# ─── Cost & Alerts ────────────────────────────────────────────────
variable "budget_amount_usd" {
  description = "Monthly budget in USD"
  type        = number
  default     = 50
}

variable "alert_email" {
  description = "Email address for budget and firewall alerts"
  type        = string
}