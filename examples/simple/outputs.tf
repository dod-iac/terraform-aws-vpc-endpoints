output "endpoints" {
  value = module.vpc_endpoints.endpoints
}

output "endpoint_services" {
  value = module.vpc_endpoints.endpoint_services
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.test.name
}
