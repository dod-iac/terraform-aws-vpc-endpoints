/**
 * ## Usage
 *
 * Creates a set of VPC endpoints for the given VPC.
 *
 * ```hcl
 * module "vpc" {
 *   source  = "terraform-aws-modules/vpc/aws"
 *   version = "3.1.0"
 *
 *   ...
 * }
 *
 * resource "aws_security_group" "endpoint" {
 *   name        = format("app-%s-vpc-endpoint", var.application)
 *   description = "A security group for PrivateLink endpoints"
 *   tags        = var.tags
 *   vpc_id      = module.vpc.vpc_id
 *   ingress {
 *     from_port   = 443
 *     to_port     = 443
 *     protocol    = "tcp"
 *     cidr_blocks = ["0.0.0.0/0"]
 *   }
 *   egress {
 *     from_port   = 0
 *     to_port     = 0
 *     protocol    = "-1"
 *     cidr_blocks = ["0.0.0.0/0"]
 *   }
 *   lifecycle {
 *     create_before_destroy = true
 *   }
 * }
 *
 * module "vpc_endpoints" {
 *   source = "dod-iac/vpc-endpoints/aws"
 *
 *   route_table_ids    = flatten([
 *     module.vpc.intra_route_table_ids,
 *     module.vpc.private_route_table_ids,
 *     module.vpc.public_route_table_ids
 *   ])
 *   security_group_ids = [aws_security_group.endpoint.id]
 *   subnet_ids         = module.vpc.private_subnets
 *   vpc_id             = module.vpc.vpc_id
 *
 *   tags  = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
 * ```
 *
 * ## Testing
 *
 * Run all terratest tests using the `terratest` script.  If using `aws-vault`, you could use `aws-vault exec $AWS_PROFILE -- terratest`.  The `AWS_DEFAULT_REGION` environment variable is required by the tests.  Use `TT_SKIP_DESTROY=1` to not destroy the infrastructure created during the tests.  Use `TT_VERBOSE=1` to log all tests as they are run.  Use `TT_TIMEOUT` to set the timeout for the tests, with the value being in the Go format, e.g., 15m.  The go test command can be executed directly, too.
 *
 * ## Terraform Version
 *
 * Terraform 0.13. Pin module version to ~> 1.0.0 . Submit pull-requests to master branch.
 *
 * Terraform 0.11 and 0.12 are not supported.
 *
 * ## License
 *
 * This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.
 */

data "aws_region" "current" {}

locals {
  endpoints = {

    # Athena

    athena = {
      enabled             = var.enable_athena_endpoints
      service             = "athena"
      private_dns_enabled = true
      tags                = { Name = "athena-vpc-endpoint" }
    },

    # CloudTrail

    cloudtrail = {
      enabled             = var.enable_cloudtrail_endpoints
      service             = "cloudtrail"
      private_dns_enabled = true
      tags                = { Name = "cloudtrail-vpc-endpoint" }
    },

    # CloudWatch

    logs = {
      enabled             = var.enable_cloudwatch_endpoints
      service             = "logs"
      private_dns_enabled = true
      tags                = { Name = "logs-vpc-endpoint" }
    },

    # EBS

    ebs = {
      enabled             = var.enable_ec2_endpoints
      service             = "ebs"
      private_dns_enabled = true
      tags                = { Name = "ebs-vpc-endpoint" }
    },

    # EC2

    ec2 = {
      enabled             = var.enable_ec2_endpoints
      service             = "ec2"
      private_dns_enabled = true
      tags                = { Name = "ec2-vpc-endpoint" }
    },
    ec2messages = {
      enabled             = var.enable_ec2_endpoints
      service             = "ec2messages"
      private_dns_enabled = true
      tags                = { Name = "ec2messages-vpc-endpoint" }
    },

    # ECR

    ecr_api = {
      enabled             = var.enable_ecr_endpoints
      service             = "ecr.api"
      private_dns_enabled = true
      tags                = { Name = "ecr-api-vpc-endpoint" }
    },
    ecr_dkr = {
      enabled             = var.enable_ecr_endpoints
      service             = "ecr.dkr"
      private_dns_enabled = true
      tags                = { Name = "ecr-dkr-vpc-endpoint" }
    },

    # ECS

    ecs = {
      enabled             = var.enable_ecs_endpoints
      service             = "ecs"
      private_dns_enabled = true
      tags                = { Name = "ecs-vpc-endpoint" }
    },
    ecs_agent = {
      enabled             = var.enable_ecs_endpoints
      service             = "ecs-agent"
      private_dns_enabled = true
      tags                = { Name = "ecs-agent-vpc-endpoint" }
    },
    ecs_telemetry = {
      enabled             = var.enable_ecs_endpoints
      service             = "ecs-telemetry"
      private_dns_enabled = true
      tags                = { Name = "ecs-telemetry-vpc-endpoint" }
    },

    # KMS

    kms = {
      enabled             = var.enable_kms_endpoints
      service             = "kms"
      private_dns_enabled = true
      tags                = { Name = "kms-vpc-endpoint" }
    },

    # Lambda

    lambda = {
      enabled             = var.enable_lambda_endpoints
      service             = "lambda"
      private_dns_enabled = true
      tags                = { Name = "lambda-vpc-endpoint" }
    },

    # S3

    s3 = {
      enabled      = var.enable_s3_endpoints
      service      = "s3"
      service_type = "Gateway"
      tags         = { Name = "s3-vpc-endpoint" }
    },

    # SageMaker

    sagemaker_api = {
      enabled             = var.enable_sagemaker_endpoints
      service             = "sagemaker.api"
      private_dns_enabled = true
      tags                = { Name = "sagemaker-api-vpc-endpoint" }
    },
    sagemaker_notebook = {
      enabled             = var.enable_sagemaker_endpoints
      service_name        = format("aws.sagemaker.%s.notebook", data.aws_region.current.name)
      private_dns_enabled = true
      tags                = { Name = "sagemaker-notebook-vpc-endpoint" }
    },
    sagemaker_runtime = {
      enabled             = var.enable_sagemaker_endpoints
      service             = "sagemaker.runtime"
      private_dns_enabled = true
      tags                = { Name = "sagemaker-runtime-vpc-endpoint" }
    },

    # SNS

    sns = {
      enabled             = var.enable_sns_endpoints
      service             = "sns"
      private_dns_enabled = true
      tags                = { Name = "sns-vpc-endpoint" }
    },

    # SSM

    ssm = {
      enabled             = var.enable_ssm_endpoints
      service             = "ssm"
      private_dns_enabled = true
      tags                = { Name = "ssm-vpc-endpoint" }
    },

    ssmmessages = {
      enabled             = var.enable_ssm_endpoints
      service             = "ssmmessages"
      private_dns_enabled = true
      tags                = { Name = "ssmmessages-vpc-endpoint" }
    },

    # SQS

    sqs = {
      enabled             = var.enable_sqs_endpoints
      service             = "sqs"
      private_dns_enabled = true
      tags                = { Name = "sqs-vpc-endpoint" }
    },

    # STS

    sts = {
      enabled             = var.enable_sts_endpoints
      service             = "sts"
      private_dns_enabled = true
      tags                = { Name = "sts-vpc-endpoint" }
    },

  }
}

data "aws_vpc_endpoint_service" "main" {
  for_each = {
    for k, v in local.endpoints : k => v
    if coalesce(lookup(v, "enabled", true), true)
  }

  service      = lookup(each.value, "service", null)
  service_name = lookup(each.value, "service_name", null)

  filter {
    name   = "service-type"
    values = [lookup(each.value, "service_type", "Interface")]
  }
}

resource "aws_vpc_endpoint" "main" {
  for_each = {
    for k, v in local.endpoints : k => v
    if coalesce(lookup(v, "enabled", true), true)
  }

  // Accept the VPC endpoint (the VPC endpoint and service need to be in the same AWS account).
  auto_accept = lookup(each.value, "auto_accept", null)

  policy = lookup(each.value, "policy", null)

  private_dns_enabled = lookup(each.value, "service_type", "Interface") == "Interface" ? lookup(each.value, "private_dns_enabled", null) : null

  route_table_ids = lookup(each.value, "service_type", "Interface") == "Gateway" ? coalesce(lookup(each.value, "route_table_ids", null), var.route_table_ids) : null

  // The verbose service name for each service for the region
  service_name = data.aws_vpc_endpoint_service.main[each.key].service_name

  // Assume each endpoint is an Interface type unless otherwise specified.
  vpc_endpoint_type = lookup(each.value, "service_type", "Interface")

  // The VPC for which the endpoints will be used.
  vpc_id = var.vpc_id

  security_group_ids = lookup(each.value, "service_type", "Interface") == "Interface" ? distinct(concat(var.security_group_ids, lookup(each.value, "security_group_ids", []))) : null

  subnet_ids = lookup(each.value, "service_type", "Interface") == "Interface" ? distinct(concat(var.subnet_ids, lookup(each.value, "subnet_ids", []))) : null

  // Merged tags for each endpoint
  tags = merge(var.tags, lookup(each.value, "tags", {}))

  // Timeout Values
  timeouts {
    create = var.timeout_create
    update = var.timeout_update
    delete = var.timeout_delete
  }

}
