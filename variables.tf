variable "policy" {
  type        = string
  description = "If specified, the common policy to apply to all endpoints."
  default     = ""
}

variable "security_group_ids" {
  type        = list(string)
  description = "The ID of one or more security groups to associate with the network interface. Required for endpoints of type Interface."
  default     = []
}

variable "subnet_ids" {
  type        = list(string)
  description = "The ID of one or more subnets in which to create a network interface for the endpoint. Applicable for endpoints of type GatewayLoadBalancer and Interface."
  default     = []
}

variable "timeout_create" {
  type        = string
  description = "Default timeout for creating a VPC endpoint"
  default     = "10m"
}

variable "timeout_update" {
  type        = string
  description = "Default timeout for VPC endpoint modifications"
  default     = "10m"
}

variable "timeout_delete" {
  type        = string
  description = "Default timeout for destroying VPC endpoints"
  default     = "10m"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the VPC endpoints"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which the endpoint will be used"
}
