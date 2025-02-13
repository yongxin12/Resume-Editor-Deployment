# Main entry point

terraform {
  backend "s3" {
    bucket = "resume-editor-terraform-state-bucket"
    key    = "state/resume-modifier-ecs-state.tfstate"
    region = "us-east-2"
  }
}

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


output "vpc_id" {
  value = aws_vpc.production_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
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


output "alb_security_group_id" {
  value = aws_security_group.allow_web.id
}



# IAM roles and policies


resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "ecs_secrets_policy"
  description = "Allow ECS to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = "arn:aws:secretsmanager:us-east-2:376129840507:secret:OPENAI_API_KEY-irAH0G"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_policy_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}



output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}


# ECS cluster

# Create an ECS cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
}


output "ecs_cluster_id" {
  value = aws_ecs_cluster.main.id
}


# Load balancer

# Create load balancer
# Create an ALB
resource "aws_lb" "production_lb" {
  name               = "ecs-production-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = aws_subnet.public[*].id # all subnet

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "market_backend_tg" {
  name        = var.lb_target_group_name_1
  port        = var.lb_target_group_port_1
  protocol    = var.lb_target_group_protocol
  vpc_id      = aws_vpc.production_vpc.id
  target_type = var.lb_target_group_target_type

  health_check {
    path                = "/"
    port                = var.lb_target_group_port_1
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "market_frontend_tg" {
  name        = var.lb_target_group_name_2
  port        = var.lb_target_group_port_2
  protocol    = var.lb_target_group_protocol
  vpc_id      = aws_vpc.production_vpc.id
  target_type = var.lb_target_group_target_type

  health_check {
    path                = "/"
    port                = var.lb_target_group_port_2
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "editor_backend_tg" {
  name        = var.lb_target_group_name_3
  port        = var.lb_target_group_port_3
  protocol    = var.lb_target_group_protocol
  vpc_id      = aws_vpc.production_vpc.id
  target_type = var.lb_target_group_target_type

  health_check {
    path                = "/"
    port                = var.lb_target_group_port_3
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "editor_frontend_tg" {
  name        = var.lb_target_group_name_4
  port        = var.lb_target_group_port_4
  protocol    = var.lb_target_group_protocol
  vpc_id      = aws_vpc.production_vpc.id
  target_type = var.lb_target_group_target_type

  health_check {
    path                = "/"
    port                = var.lb_target_group_port_4
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}



resource "aws_lb_listener" "market_backend_lb_listener" {
  load_balancer_arn = aws_lb.production_lb.arn
  port              = var.lb_listener_port_1
  protocol          = var.lb_listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.market_backend_tg.arn
  }
}

resource "aws_lb_listener" "market_frontend_lb_listener" {
  load_balancer_arn = aws_lb.production_lb.arn
  port              = var.lb_listener_port_2
  protocol          = var.lb_listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.market_frontend_tg.arn
  }
}

resource "aws_lb_listener" "editor_backend_lb_listener" {
  load_balancer_arn = aws_lb.production_lb.arn
  port              = var.lb_listener_port_3
  protocol          = var.lb_listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.editor_backend_tg.arn
  }
}

resource "aws_lb_listener" "editor_frontend_lb_listener" {
  load_balancer_arn = aws_lb.production_lb.arn
  port              = var.lb_listener_port_4
  protocol          = var.lb_listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.editor_frontend_tg.arn
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.production_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-2:376129840507:certificate/f72942a2-9b55-422c-bb66-0cb93407d547"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.market_backend_tg.arn
  }
}


resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.production_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "market_backend_path_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = var.lb_listener_rule_priority_1

  condition {
    path_pattern {
      values = [var.lb_listener_rule_path_1]
    }

  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.market_backend_tg.arn
  }
}

resource "aws_lb_listener_rule" "frontend_path_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = var.lb_listener_rule_priority_2

  condition {
    path_pattern {
      values = [var.lb_listener_rule_path_2]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.market_frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "editor_backend_path_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = var.lb_listener_rule_priority_3

  condition {
    path_pattern {
      values = [var.lb_listener_rule_path_3]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.editor_backend_tg.arn
  }
}

resource "aws_lb_listener_rule" "editor_frontend_path_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = var.lb_listener_rule_priority_4

  condition {
    path_pattern {
      values = [var.lb_listener_rule_path_4]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.editor_frontend_tg.arn
  }
}


## route 53
resource "aws_route53_record" "main_domain" {
  zone_id = var.route53_record_zone_id
  name    = var.route53_record_name
  type    = var.route53_record_type

  alias {
    name                   = aws_lb.production_lb.dns_name
    zone_id                = aws_lb.production_lb.zone_id
    evaluate_target_health = true
  }
}




output "frontend_target_group_arn" {
  value = aws_lb_target_group.market_frontend_tg.arn
}

output "main_target_group_arn" {
  value = aws_lb_target_group.market_backend_tg.arn
}

output "alb_dns_name" {
  value = aws_lb.production_lb.dns_name
}


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
      image     = "376129840507.dkr.ecr.us-east-2.amazonaws.com/market-backend:latest"
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
      image     = "376129840507.dkr.ecr.us-east-2.amazonaws.com/market-frontend:latest"
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

resource "aws_ecs_task_definition" "editor_backend" {

  family                   = "editor_backend_family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "editor_backend"
      image     = "376129840507.dkr.ecr.us-east-2.amazonaws.com/editor-backend:latest"
      cpu       = 256
      essential = true

      portMappings = [
        {
          containerPort = 5001
          hostPort      = 5001
          protocol      = "tcp"
        }
      ]
      # hardcoding arn
      # plain text
      # secrets = [
      #   {
      #     name      = "OPENAI_API_KEY"
      #     valueFrom = "arn:aws:secretsmanager:us-east-2:376129840507:secret:OPENAI_API_KEY-irAH0G"
      #   }
      # ]
      secrets = [
        {
          name      = "OPENAI_API_KEY"
          valueFrom = "arn:aws:secretsmanager:us-east-2:376129840507:secret:OPENAI_API_KEY-irAH0G:OPENAI_API_KEY::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/editor_backend"
          "awslogs-region"        = "us-east-2"
          "max-buffer-size"       = "25m"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "editor_frontend" {

  family                   = "editor_frontend_family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "editor_frontend"
      image     = "376129840507.dkr.ecr.us-east-2.amazonaws.com/editor-frontend:latest"
      cpu       = 256
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/editor_frontend"
          "awslogs-region"        = "us-east-2"
          "max-buffer-size"       = "25m"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "frontend_service" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.market_frontend.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.allow_web.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.market_frontend_tg.arn
    container_name   = "market_frontend"
    container_port   = 3000
  }
}

resource "aws_ecs_service" "backend_service" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.market_backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.allow_web.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.market_backend_tg.arn
    container_name   = "market_backend"
    container_port   = 5001
  }
}


resource "aws_ecs_service" "editor_frontend_service" {
  name            = "editor-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.editor_frontend.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.allow_web.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.editor_frontend_tg.arn
    container_name   = "editor_frontend"
    container_port   = 80
  }
}


resource "aws_ecs_service" "editor_backend_service" {
  name            = "editor-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.editor_backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.allow_web.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.editor_backend_tg.arn
    container_name   = "editor_backend"
    container_port   = 5001
  }
}
