<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Usage

Creates a set of VPC endpoints for the given VPC.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.1.0"

  ...
}

resource "aws_security_group" "endpoint" {
  name        = format("app-%s-vpc-endpoint", var.application)
  description = "A security group for PrivateLink endpoints"
  tags        = var.tags
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

module "vpc_endpoints" {
  source = "dod-iac/vpc-endpoints/aws"

  route_table_ids    = flatten([
    module.vpc.intra_route_table_ids,
    module.vpc.private_route_table_ids,
    module.vpc.public_route_table_ids
  ])
  security_group_ids = [aws_security_group.endpoint.id]
  subnet_ids         = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id

  tags  = {
    Application = var.application
    Environment = var.environment
    Automation  = "Terraform"
  }
}
```

## Testing

Run all terratest tests using the `terratest` script.  If using `aws-vault`, you could use `aws-vault exec $AWS_PROFILE -- terratest`.  The `AWS_DEFAULT_REGION` environment variable is required by the tests.  Use `TT_SKIP_DESTROY=1` to not destroy the infrastructure created during the tests.  Use `TT_VERBOSE=1` to log all tests as they are run.  Use `TT_TIMEOUT` to set the timeout for the tests, with the value being in the Go format, e.g., 15m.  The go test command can be executed directly, too.

## Terraform Version

Terraform 0.13. Pin module version to ~> 1.0.0 . Submit pull-requests to master branch.

Terraform 0.11 and 0.12 are not supported.

## License

This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0.0, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_vpc_endpoint.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_vpc_endpoint_service.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_athena_endpoints"></a> [enable\_athena\_endpoints](#input\_enable\_athena\_endpoints) | Enable VPC endpoints for Athena. | `bool` | `true` | no |
| <a name="input_enable_cloudtrail_endpoints"></a> [enable\_cloudtrail\_endpoints](#input\_enable\_cloudtrail\_endpoints) | Enable VPC endpoints for CloudTrail. | `bool` | `true` | no |
| <a name="input_enable_cloudwatch_endpoints"></a> [enable\_cloudwatch\_endpoints](#input\_enable\_cloudwatch\_endpoints) | Enable VPC endpoints for CloudWatch. | `bool` | `true` | no |
| <a name="input_enable_ec2_endpoints"></a> [enable\_ec2\_endpoints](#input\_enable\_ec2\_endpoints) | Enable VPC endpoints for EC2. | `bool` | `true` | no |
| <a name="input_enable_ecr_endpoints"></a> [enable\_ecr\_endpoints](#input\_enable\_ecr\_endpoints) | Enable VPC endpoints for ECR. | `bool` | `true` | no |
| <a name="input_enable_ecs_endpoints"></a> [enable\_ecs\_endpoints](#input\_enable\_ecs\_endpoints) | Enable VPC endpoints for ECS. | `bool` | `true` | no |
| <a name="input_enable_kms_endpoints"></a> [enable\_kms\_endpoints](#input\_enable\_kms\_endpoints) | Enable VPC endpoints for KMS. | `bool` | `true` | no |
| <a name="input_enable_lambda_endpoints"></a> [enable\_lambda\_endpoints](#input\_enable\_lambda\_endpoints) | Enable VPC endpoints for Lambda. | `bool` | `true` | no |
| <a name="input_enable_s3_endpoints"></a> [enable\_s3\_endpoints](#input\_enable\_s3\_endpoints) | Enable VPC endpoints for S3. | `bool` | `true` | no |
| <a name="input_enable_sagemaker_endpoints"></a> [enable\_sagemaker\_endpoints](#input\_enable\_sagemaker\_endpoints) | Enable VPC endpoints for SageMaker. | `bool` | `true` | no |
| <a name="input_enable_secretsmanager_endpoints"></a> [enable\_secretsmanager\_endpoints](#input\_enable\_secretsmanager\_endpoints) | Enable VPC endpoints for SecretsManager. | `bool` | `true` | no |
| <a name="input_enable_sns_endpoints"></a> [enable\_sns\_endpoints](#input\_enable\_sns\_endpoints) | Enable VPC endpoints for SNS. | `bool` | `true` | no |
| <a name="input_enable_sqs_endpoints"></a> [enable\_sqs\_endpoints](#input\_enable\_sqs\_endpoints) | Enable VPC endpoints for SQS. | `bool` | `true` | no |
| <a name="input_enable_ssm_endpoints"></a> [enable\_ssm\_endpoints](#input\_enable\_ssm\_endpoints) | Enable VPC endpoints for SSM. | `bool` | `true` | no |
| <a name="input_enable_sts_endpoints"></a> [enable\_sts\_endpoints](#input\_enable\_sts\_endpoints) | Enable VPC endpoints for STS. | `bool` | `true` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | If specified, the common policy to apply to all endpoints. | `string` | `""` | no |
| <a name="input_route_table_ids"></a> [route\_table\_ids](#input\_route\_table\_ids) | One or more route table IDs. Applicable for endpoints of type Gateway. | `list(string)` | `[]` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface. Required for endpoints of type Interface. | `list(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The ID of one or more subnets in which to create a network interface for the endpoint. Applicable for endpoints of type GatewayLoadBalancer and Interface. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the VPC endpoints | `map(string)` | `{}` | no |
| <a name="input_timeout_create"></a> [timeout\_create](#input\_timeout\_create) | Default timeout for creating a VPC endpoint | `string` | `"10m"` | no |
| <a name="input_timeout_delete"></a> [timeout\_delete](#input\_timeout\_delete) | Default timeout for destroying VPC endpoints | `string` | `"10m"` | no |
| <a name="input_timeout_update"></a> [timeout\_update](#input\_timeout\_update) | Default timeout for VPC endpoint modifications | `string` | `"10m"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC in which the endpoint will be used | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint_services"></a> [endpoint\_services](#output\_endpoint\_services) | n/a |
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
