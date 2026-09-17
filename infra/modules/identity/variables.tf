variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Hub resource group name"
  type        = string
}

variable "spoke_app_resource_group_name" {
  description = "Spoke App resource group name"
  type        = string
}

variable "spoke_data_resource_group_name" {
  description = "Spoke Data resource group name"
  type        = string
}