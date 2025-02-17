# VPC and subnets

# Create a VPC
resource "aws_vpc" "production_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true #  Error: creating RDS DB Instance (resume-app-db): operation error RDS: CreateDBInstance, https response error StatusCode: 400, RequestID: 7f692d42-13d2-4e2e-86d9-c7d55f719d05, InvalidVPCNetworkStateFault: Cannot create a publicly accessible DBInstance.  The specified VPC does not support DNS resolution, DNS hostnames, or both. Update the VPC and then try again
  enable_dns_hostnames = true
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

  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = var.sg_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow inbound access to RDS from ECS"
  vpc_id      = aws_vpc.production_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For testing only
    # security_groups = [aws_security_group.allow_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}


# Create RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.public[*].id # Use private subnets for production

  tags = {
    Name = "rds-subnet-group"
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "postgres" {
  name   = "postgres15-params"
  family = "postgres15"

  parameter {
    name  = "log_statement"
    value = "none"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}


# Create RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier             = "resume-app-db"
  engine                 = "postgres"
  engine_version         = "15.7"
  instance_class         = "db.t4g.micro" # Free tier eligible
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "resume_app"
  username               = "postgres"
  password               = "postgres"
  parameter_group_name   = aws_db_parameter_group.postgres.name
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = true # Keep false for production
  skip_final_snapshot    = true
  multi_az               = false # Enable for production
  storage_encrypted      = true

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  tags = {
    Name = "resume-app-database"
  }
}


# Create an ECS cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
}
