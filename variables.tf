variable "enable_athena_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for Athena."
  default     = true
}

variable "enable_cloudtrail_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for CloudTrail."
  default     = true
}

variable "enable_cloudwatch_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for CloudWatch."
  default     = true
}

variable "enable_ec2_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for EC2."
  default     = true
}

variable "enable_ecr_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for ECR."
  default     = true
}

variable "enable_ecs_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for ECS."
  default     = true
}

variable "enable_kms_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for KMS."
  default     = true
}

variable "enable_lambda_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for Lambda."
  default     = true
}

variable "enable_s3_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for S3."
  default     = true
}

variable "enable_sagemaker_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for SageMaker."
  default     = true
}

variable "enable_secretsmanager_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for SecretsManager."
  default     = true
}

variable "enable_sns_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for SNS."
  default     = true
}

variable "enable_ssm_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for SSM."
  default     = true
}

variable "enable_sqs_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for SQS."
  default     = true
}

variable "enable_sts_endpoints" {
  type        = bool
  description = "Enable VPC endpoints for STS."
  default     = true
}

variable "policy" {
  type        = string
  description = "If specified, the common policy to apply to all endpoints."
  default     = ""
}

variable "route_table_ids" {
  type        = list(string)
  description = "One or more route table IDs. Applicable for endpoints of type Gateway."
  default     = []
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
