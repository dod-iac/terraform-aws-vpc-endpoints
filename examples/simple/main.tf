// =================================================================
//
// Work of the U.S. Department of Defense, Defense Digital Service.
// Released as open source under the MIT License.  See LICENSE file.
//
// =================================================================

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

  tags = merge({
    Name = format("ec2-instance-%s", var.test_name)
  }, var.tags)

  lifecycle {
    ignore_changes = [
      user_data
    ]
  }
}
