base_cidr = "10.100.20.0/20"
subnets = {
  abc = {
    size     = 2048
    az_count = 1
  }
  bcd = {
    # new_bits = 
    size     = 1024
    az_count = 2
  }
}
