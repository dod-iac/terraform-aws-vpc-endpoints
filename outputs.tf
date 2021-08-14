output "endpoint_services" {
  value = data.aws_vpc_endpoint_service.main.*
}

output "endpoints" {
  value = aws_vpc_endpoint.main.*
}
