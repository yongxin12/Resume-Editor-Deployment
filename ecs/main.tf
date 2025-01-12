provider "aws" {
  region = "us-east-2" # Change as per your region
}

resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = "my_ecs_cluster"
}

resource "aws_ecs_task_definition" "market_frontend" {
  family                   = "market_frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # Adjust based on requirements
  memory                   = "512" # Adjust based on requirements

  container_definitions = <<DEFINITION
[
  {
    "name": "market_frontend",
    "image": "376129840507.dkr.ecr.us-east-2.amazonaws.com/market_frontend:latest",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_task_definition" "market_backend" {
  family                   = "market_backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = <<DEFINITION
[
  {
    "name": "market_backend",
    "image": "376129840507.dkr.ecr.us-east-2.amazonaws.com/market_backend:latest",
    "portMappings": [
      {
        "containerPort": 5001,
        "hostPort": 5001
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "market_frontend" {
  name            = "market_frontend-service"
  cluster         = aws_ecs_cluster.my_ecs_cluster.id
  task_definition = aws_ecs_task_definition.market_frontend.arn
  desired_count   = 1

  network_configuration {
    subnets         = ["subnet-0123456789abcdef0"] # Replace with actual subnet IDs
    security_groups = ["sg-0123456789abcdef0"]   # Replace with actual SG IDs
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "market_backend" {
  name            = "market_backend-service"
  cluster         = aws_ecs_cluster.my_ecs_cluster.id
  task_definition = aws_ecs_task_definition.market_backend.arn
  desired_count   = 1

  network_configuration {
    subnets         = ["subnet-0123456789abcdef0"]
    security_groups = ["sg-0123456789abcdef0"]
    assign_public_ip = true
  }
}

output "market_frontend_service_arn" {
  value = aws_ecs_service.market_frontend.arn
}

output "market_backend_service_arn" {
  value = aws_ecs_service.market_backend.arn
}
