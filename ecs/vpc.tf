variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# Define VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    name = "main"
  }
}

# Add 2 subnets
resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  map_public_ip_on_launch = true
  availability_zone = ""
}
