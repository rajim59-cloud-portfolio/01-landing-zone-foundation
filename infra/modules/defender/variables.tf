variable "enable_servers_pricing" {
  description = "Enable Defender for Servers (P1)"
  type        = bool
  default     = false
}

variable "enable_cspm" {
  description = "Enable Defender CSPM (paid tier)"
  type        = bool
  default     = false
}