variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "retention_days" {
  type    = number
  default = 30
}

variable "daily_quota_gb" {
  type    = number
  default = 1
}

variable "budget_amount_usd" {
  type    = number
  default = 50
}

variable "alert_email" {
  type = string
}

variable "firewall_resource_id" {
  type = string
}

variable "bastion_resource_id" {
  type = string
}

variable "spoke_app_vnet_id" {
  type = string
}

variable "spoke_data_vnet_id" {
  type = string
}