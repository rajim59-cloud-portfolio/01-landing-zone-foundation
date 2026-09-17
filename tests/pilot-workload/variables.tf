variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region (must match landing zone region)"
  type        = string
  default     = "malaysiawest"
}

variable "tags" {
  description = "Required tags — enforced by Azure Policy"
  type = object({
    CostCenter = string
    Env        = string
    Owner      = string
    Project    = string
  })
}

variable "admin_username" {
  description = "Admin username for the test VM"
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "VM size (B-series is cheapest)"
  type        = string
  default     = "Standard_B1s"
}