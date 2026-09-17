variable "scope_id" {
  description = "Scope where policies are assigned (subscription or management group)"
  type        = string
}

variable "allowed_locations" {
  description = "List of allowed Azure regions"
  type        = list(string)
  default     = ["malaysiawest", "southeastasia"]
}

variable "required_tags" {
  description = "List of required tags on all resources"
  type        = list(string)
  default     = ["CostCenter", "Env", "Owner"]
}