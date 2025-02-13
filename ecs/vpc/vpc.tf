# VPC and subnets

# Create a VPC
resource "aws_vpc" "production_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "production-vpc"
  }
}

# Create an internet gateway  //make all the subnet public?
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.production_vpc.id
}


# Create route table
resource "aws_route_table" "production_route_table" {
  vpc_id = aws_vpc.production_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    cidr_block = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "production-route-table"
  }
}

# Create subnets in different Availability Zones
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.production_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# Associate route table with subnets
resource "aws_route_table_association" "whatever" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.production_route_table.id
}


output "vpc_id" {
  value = aws_vpc.production_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
}
