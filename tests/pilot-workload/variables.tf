variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Deployment region"
  type        = string
  default     = "malaysiawest"
}

variable "admin_username" {
  description = "VM admin username"
  type        = string
  default     = "azureuser"
}