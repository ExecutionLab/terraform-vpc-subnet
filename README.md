# Subnets Terraform Module

This module automates the calculation, validation, and generation of subnet CIDR blocks within a given base CIDR.
It supports flexible subnet sizing using either explicit size or new bits, and ensures that total IP requirements do not exceed the base CIDR capacity.

## Features
- Calculates subnet CIDR blocks based on input requirements
- Supports subnet sizing by `size` (number of IPs, power of 2) or `new_bits`
- Handles multiple subnets and multiple availability zones (AZs)
- Validates that total required IPs fit within the base CIDR
- Outputs detailed subnet configuration and allocation summary

## Usage

```hcl
module "subnets" {
  source    = "github.com/ExecutionLab/terraform-vpc-subnet"
  base_cidr = "10.100.20.0/20"
  subnets = {
    public = {
      size     = 2048
      az_count = 1
    }
    private = {
      new_bits = 4
      az_count = 2
    }
  }
}
```

## Variables

| Name       | Type   | Description                                 | Required |
|------------|--------|---------------------------------------------|----------|
| base_cidr  | string | Base CIDR block for all subnets - VPC CIDR  | Yes      |
| subnets    | map    | Map of subnet configs (see below)           | Yes      |

## Outputs

| Name            | Description                                      |
|-----------------|--------------------------------------------------|
| base_cidr       | VPC CIDR                                          |
| subnets         | Generated subnet configurations with CIDR blocks  |
| subnet_summary  | Summary of subnet allocation (sizes, utilization) |

## Example Output

```
base_cidr = "10.100.20.0/20"
subnet_summary = {
  base_cidr_size      = 4096
  remaining_ips       = 0
  total_required_ips  = 4096
  utilization_percent = 100
}
subnets = {
  public = {
    az_count = 1
    cidrs = [
      "10.100.16.0/31",
    ]
    new_bits = 11
    size     = 2048
  }
  private = {
    az_count = 2
    cidrs = [
      "10.100.16.4/30",
      "10.100.16.8/30",
    ]
    new_bits = 10
    size     = 1024
  }
}
```
