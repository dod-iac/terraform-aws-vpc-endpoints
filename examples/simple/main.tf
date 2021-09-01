// =================================================================
//
// Work of the U.S. Department of Defense, Defense Digital Service.
// Released as open source under the MIT License.  See LICENSE file.
//
// =================================================================

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

resource "aws_eip" "nat" {
  count = 3

  vpc = true

  tags = merge(var.tags, {
    Name = format("nat-%d-%s", count.index + 1, var.test_name)
  })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.1.0"

  name = format("app-vpc-%s", var.test_name)
  cidr = "10.0.0.0/16"

  azs             = formatlist(format("%s%%s", data.aws_region.current.name), ["a", "b", "c"])
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # One NAT Gateway per subnet (default behavior)
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  reuse_nat_ips          = true
  external_nat_ip_ids    = aws_eip.nat.*.id

  # DNS Support is required to use VPC interface endpoints
  enable_dns_hostnames = true
  enable_dns_support   = true

  # DHCP
  enable_dhcp_options = true

  # Tags
  tags = var.tags
}

resource "aws_security_group" "endpoint" {

  name        = format("app-vpc-endpoint-%s", var.test_name)
  description = "A security group for PrivateLink endpoints"

  vpc_id = module.vpc.vpc_id

  # Ingress rules
  # Ingress on 443 required
  # https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tags
  tags = var.tags

  # Lifecycle rules
  lifecycle {
    create_before_destroy = true
  }
}

module "vpc_endpoints" {
  source = "../../"

  security_group_ids = [aws_security_group.endpoint.id]

  subnet_ids = module.vpc.private_subnets

  tags = var.tags

  vpc_id = module.vpc.vpc_id
}

#
# The following resources are used for testing.
#

resource "aws_s3_bucket" "test" {
  bucket = var.test_name
  tags   = var.tags

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "test" {
  bucket = aws_s3_bucket.test.id

  # Block new public ACLs and uploading public objects
  block_public_acls = true

  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = true

  # Block new public bucket policies
  block_public_policy = true

  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "test" {
  bucket = aws_s3_bucket.test.id
  acl    = "bucket-owner-full-control"
  key    = "endpoints.json"
  content = jsonencode([for k, v in module.vpc_endpoints.endpoints : {
    name             = v.tags.Name
    id               = v.id
    arn              = v.arn
    service_id       = module.vpc_endpoints.endpoint_services[k].service_id
    private_dns_name = module.vpc_endpoints.endpoint_services[k].private_dns_name
  }])
  server_side_encryption = "AES256"
}

resource "aws_cloudwatch_log_group" "test" {
  name = var.test_name
  tags = var.tags
}

resource "aws_cloudwatch_log_stream" "test_results" {
  name           = "results"
  log_group_name = aws_cloudwatch_log_group.test.name
}

data "aws_iam_policy_document" "ec2_instance_role_policy" {
  statement {
    sid = "CreateCloudWatchLogStreamsAndPutLogEvents"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect = "Allow"
    resources = [
      format(
        "arn:%s:logs:%s:%s:log-group:%s:log-stream:%s",
        data.aws_partition.current.partition,
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
        aws_cloudwatch_log_group.test.name,
        aws_cloudwatch_log_stream.test_results.name,
      )
    ]
  }
  statement {
    sid = "GetObject"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    effect    = "Allow"
    resources = formatlist("%s/*", [
      aws_s3_bucket.test.arn
    ])
  }
}

resource "aws_iam_policy" "ec2_instance_role_policy" {
  name   = format("execution-role-%s", var.test_name)
  path   = "/"
  policy = data.aws_iam_policy_document.ec2_instance_role_policy.json
}

resource "aws_security_group" "ec2_instance" {
  name        = format("ec2-instance-%s", var.test_name)
  description = format("Allow traffic to test EC2 instance for %s", var.test_name)
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "ec2_instance_role" {
  source  = "dod-iac/ec2-instance-role/aws"
  version = "1.0.1"

  name = format("ec2-instance-role-%s", var.test_name)

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_policy" {
  role       = module.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_role_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_role" {
  name = module.ec2_instance_role.name
  role = module.ec2_instance_role.name
}

resource "aws_key_pair" "test" {
  key_name   = format("instance-%s", var.test_name)
  public_key = file(var.public_key)
}

resource "aws_instance" "test" {
  ami = var.ec2_image_id

  instance_type = "t3.micro"

  key_name = aws_key_pair.test.key_name

  root_block_device {
    volume_type           = "standard"
    volume_size           = "8"
    delete_on_termination = true
    encrypted             = false
    kms_key_id            = null

    # Not used by specified to minimize state drift
    iops = 0

    tags = merge({
      Name = format("ec2-instance-%s", var.test_name)
    }, var.tags)
  }

  vpc_security_group_ids = [
    aws_security_group.ec2_instance.id
  ]

  subnet_id = module.vpc.public_subnets.0

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_role.name

  # disable_api_termination, ebs_optimized, hiberation, and monitoring, default to false,
  # but are set to minimize state drift
  disable_api_termination = false
  ebs_optimized           = false
  hibernation             = false
  monitoring              = false

  user_data = templatefile(format("%s/userdata.tpl", path.module), {
    log_group_name  = aws_cloudwatch_log_group.test.name,
    log_stream_name = aws_cloudwatch_log_stream.test_results.name,
    bucket          = aws_s3_bucket.test.id
    region          = data.aws_region.current.name
    tags            = merge(var.tags, { Name = var.test_name })
  })

  tags = merge({
    Name = format("ec2-instance-%s", var.test_name)
  }, var.tags)

  lifecycle {
    ignore_changes = [
      user_data
    ]
  }
}
