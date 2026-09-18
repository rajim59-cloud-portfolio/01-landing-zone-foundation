variable "root_management_group_id" {
  description = "Existing tenant root management group ID (usually the tenant ID)"
  type        = string
}

variable "platform_subscription_ids" {
  description = "Subscription IDs to place under the Platform MG"
  type        = list(string)
  default     = []
}

variable "workloads_subscription_ids" {
  description = "Subscription IDs to place under the Workloads MG"
  type        = list(string)
  default     = []
}

variable "sandbox_subscription_ids" {
  description = "Subscription IDs to place under the Sandbox MG"
  type        = list(string)
  default     = []
}