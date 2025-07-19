# ==============================================================================
# SUBNET CIDR CALCULATION AND VALIDATION
# Generate by Claude
# Author: lai.tran@executionlab.asia
# ==============================================================================

# Calculate real base CIDR (network address) and capacity
locals {
  # Extract the actual network address from the input CIDR
  real_base_cidr = cidrsubnet(var.base_cidr, 0, 0)

  # Calculate the prefix length
  prefix_length = tonumber(split("/", var.base_cidr)[1])

  # Calculate base CIDR capacity
  base_cidr_size = pow(2, 32 - local.prefix_length)
}

# ==============================================================================
# SUBNET REQUIREMENTS CALCULATION
# ==============================================================================

locals {
  # Calculate IP requirements for each subnet type
  subnet_requirements = {
    for subnet_key, subnet in var.subnets : subnet_key => {
      # IPs per availability zone
      ips_per_az = subnet.size != null ? subnet.size : pow(2, subnet.new_bits)

      # Total IPs across all AZs for this subnet type
      total_ips = (subnet.size != null ? subnet.size : pow(2, subnet.new_bits)) * subnet.az_count

      # Store original configuration for reference
      az_count = subnet.az_count
      size     = subnet.size
      new_bits = subnet.new_bits
    }
  }

  # Calculate total IP addresses required across all subnets
  total_required_ips = sum([
    for subnet_key, req in local.subnet_requirements : req.total_ips
  ])
}

# ==============================================================================
# VALIDATION
# ==============================================================================

locals {
  error_message = "ERROR: Total required IPs (${local.total_required_ips}) exceeds base CIDR capacity (${local.base_cidr_size}). Real base CIDR: ${local.real_base_cidr}"

  # Validate that total IP requirements don't exceed base CIDR capacity
  validate_capacity = local.total_required_ips <= local.base_cidr_size ? true : tobool(local.error_message)
}

# ==============================================================================
# SUBNET NETWORK CONFIGURATION
# ==============================================================================

locals {
  # Create network configurations for the HashiCorp subnets module
  # This flattens the subnet configuration into individual network blocks
  subnet_networks = flatten([
    for subnet_key, subnet in var.subnets : [
      for az_index in range(subnet.az_count) : {
        name     = "${subnet_key}-${az_index + 1}"
        new_bits = subnet.new_bits != null ? subnet.new_bits : ceil(log(subnet.size, 2))
      }
    ]
  ])
}

# ==============================================================================
# CIDR BLOCK GENERATION
# ==============================================================================

# Generate subnet CIDR blocks using HashiCorp subnets module with real base CIDR
module "subnet_blocks" {
  source = "hashicorp/subnets/cidr"

  # Use the real/normalized base CIDR network address
  base_cidr_block = local.real_base_cidr
  networks        = local.subnet_networks

  # Ensure validation happens before module execution
  depends_on = [local.validate_capacity]
}

# ==============================================================================
# OUTPUT FORMATTING
# ==============================================================================

locals {
  # Format the generated CIDR blocks into the desired output structure
  formatted_subnets = {
    for subnet_key, subnet in var.subnets : subnet_key => {
      # Array of CIDR blocks for each availability zone
      cidrs = [
        for az_index in range(subnet.az_count) :
        module.subnet_blocks.network_cidr_blocks["${subnet_key}-${az_index + 1}"]
      ]

      # Calculated subnet size (IPs per subnet)
      size = subnet.size != null ? subnet.size : pow(2, subnet.new_bits)

      # Network bits to add to base CIDR
      new_bits = subnet.new_bits != null ? subnet.new_bits : ceil(log(subnet.size, 2))

      # Number of availability zones
      az_count = subnet.az_count
    }
  }
}
