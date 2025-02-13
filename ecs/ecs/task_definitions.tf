
resource "aws_ecs_task_definition" "market_backend" {
  
  family                   = "market_backend_family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "market_backend"
      image     = "376129840507.dkr.ecr.us-east-2.amazonaws.com/market_backend:latest"
      cpu       = 256
      essential = true

      portMappings = [
        {
          containerPort = 5001
          hostPort      = 5001
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/market_backend"
          "awslogs-region"        = "us-east-2"
          "max-buffer-size"       = "25m"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "market_frontend" {
  
  family                   = "market_frontend_family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "market_frontend"
      image     = "376129840507.dkr.ecr.us-east-2.amazonaws.com/market_frontend:latest"
      cpu       = 256
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/market_frontend"
          "awslogs-region"        = "us-east-2"
          "max-buffer-size"       = "25m"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}