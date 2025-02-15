# VPC and subnets

# Create a VPC
resource "aws_vpc" "production_vpc" {
  cidr_block = var.vpc_cidr_block

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


  tags = {
    Name = "production-route-table"
  }
}


# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
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


# Create security group 
resource "aws_security_group" "allow_web" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.production_vpc.id

  # 1
  ingress {
    description = var.sg_ingress_description_1
    from_port   = var.sg_ingress_port_1
    to_port     = var.sg_ingress_port_1
    protocol    = var.sg_ingress_protocol
    cidr_blocks = ["0.0.0.0/0"]
  }
  # 2
  ingress {
    description = var.sg_ingress_description_2
    from_port   = var.sg_ingress_port_2
    to_port     = var.sg_ingress_port_2
    protocol    = var.sg_ingress_protocol
    cidr_blocks = ["0.0.0.0/0"]
  }
  # 3
  ingress {
    description = var.sg_ingress_description_3
    from_port   = var.sg_ingress_port_3
    to_port     = var.sg_ingress_port_3
    protocol    = var.sg_ingress_protocol
    cidr_blocks = ["0.0.0.0/0"]
  }
  # 4
  ingress {
    description = var.sg_ingress_description_4
    from_port   = var.sg_ingress_port_4
    to_port     = var.sg_ingress_port_4
    protocol    = var.sg_ingress_protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NFS traffic
  ingress {
    description = "Allow NFS traffic"
    from_port   = 2049 # NFS requires this
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Allow traffic from within the VPC
  }



  # Allow HTTP
  ingress {
    description = var.sg_ingress_description_http
    from_port   = var.sg_ingress_port_http
    to_port     = var.sg_ingress_port_http
    protocol    = var.sg_ingress_protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS
  ingress {
    description = var.sg_ingress_description_https
    from_port   = var.sg_ingress_port_https
    to_port     = var.sg_ingress_port_https
    protocol    = var.sg_ingress_protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




# Create an ECS cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
}