output "endpoints" {
  value = module.vpc_endpoints.endpoints
}

output "endpoint_services" {
  value = module.vpc_endpoints.endpoint_services
}
