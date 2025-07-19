
# Outputs
output "base_cidr" {
  description = "Base CIDR block used for subnet generation"
  value       = var.base_cidr
}

output "subnets" {
  description = "Generated subnet configurations with CIDR blocks"
  value       = local.formatted_subnets
}

output "subnet_summary" {
  description = "Summary of subnet allocation"
  value = {
    base_cidr_size      = local.base_cidr_size
    total_required_ips  = local.total_required_ips
    remaining_ips       = local.base_cidr_size - local.total_required_ips
    utilization_percent = floor((local.total_required_ips / local.base_cidr_size) * 10000) / 100
  }
}
