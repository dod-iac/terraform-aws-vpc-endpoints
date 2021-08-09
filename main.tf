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
 * Run all terratest tests using the `terratest` script.  If using `aws-vault`, you could use `aws-vault exec $AWS_PROFILE -- terratest`.  The `AWS_DEFAULT_REGION` environment variable is required by the tests.  Use `TT_SKIP_DESTROY=1` to not destroy the infrastructure created during the tests.  Use `TT_VERBOSE=1` to log all tests as they are run.  The go test command can be executed directly, too.
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
      service             = "athena"
      private_dns_enabled = true
    },

    # CloudWatch

    logs = {
      service             = "logs"
      private_dns_enabled = true
    },

    # EC2

    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
    },

    # ECS and ECR

    ecs = {
      service             = "ecs"
      private_dns_enabled = true
    },
    ecs_agent = {
      service             = "ecs-agent"
      private_dns_enabled = true
    },
    ecs_telemetry = {
      service             = "ecs-telemetry"
      private_dns_enabled = true
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
    },

    # KMS

    kms = {
      service             = "kms"
      private_dns_enabled = true
    },

    # S3

    s3 = {
      service      = "s3"
      service_type = "Gateway"
      tags         = { Name = "s3-vpc-endpoint" }
    },

    # SageMaker

    sagemaker_api = {
      service             = "sagemaker.api"
      private_dns_enabled = true
    },
    sagemaker_runtime = {
      service             = "sagemaker.runtime"
      private_dns_enabled = true
    },

    # STS

    sts = {
      service             = "sts"
      private_dns_enabled = true
    },

  }
}

data "aws_vpc_endpoint_service" "this" {
  for_each = local.endpoints

  service      = lookup(each.value, "service", null)
  service_name = lookup(each.value, "service_name", null)

  filter {
    name   = "service-type"
    values = [lookup(each.value, "service_type", "Interface")]
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.endpoints

  // Accept the VPC endpoint (the VPC endpoint and service need to be in the same AWS account).
  auto_accept = lookup(each.value, "auto_accept", null)

  policy = lookup(each.value, "policy", null)

  private_dns_enabled = lookup(each.value, "service_type", "Interface") == "Interface" ? lookup(each.value, "private_dns_enabled", null) : null

  route_table_ids = lookup(each.value, "service_type", "Interface") == "Gateway" ? lookup(each.value, "route_table_ids", null) : null

  // The verbose service name for each service for the region
  service_name = data.aws_vpc_endpoint_service.this[each.key].service_name

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
