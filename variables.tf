variable "base_cidr" {
  description = "Base CIDR block for all subnets"
  type        = string

  validation {
    condition     = can(cidrhost(var.base_cidr, 0))
    error_message = "The base_cidr must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    size     = optional(number)
    new_bits = optional(number)
    az_count = number
  }))

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      (subnet.size != null && subnet.new_bits == null) ||
      (subnet.size == null && subnet.new_bits != null)
    ])
    error_message = "Each subnet must have either 'size' or 'new_bits' defined, but not both."
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      subnet.az_count > 0 && subnet.az_count <= 10
    ])
    error_message = "az_count must be between 1 and 10."
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      subnet.size != null ? (
        subnet.size > 16 &&
        subnet.size <= 65536 &&
        floor(log(subnet.size, 2)) == log(subnet.size, 2)
      ) : true
    ])
    error_message = "Subnet size must be a power of 2 and between 16 and 65536."
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      subnet.new_bits != null ? (
        subnet.new_bits > 0 && subnet.new_bits <= 16
      ) : true
    ])
    error_message = "new_bits must be between 1 and 16."
  }
}
