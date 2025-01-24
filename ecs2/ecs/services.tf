resource "aws_ecs_service" "frontend_service" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.market_frontend.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = aws_subnet.public[*].id
    security_groups = [aws_security_group.allow_web.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
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
    subnets         = aws_subnet.public[*].id
    security_groups = [aws_security_group.allow_web.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "market_backend"
    container_port   = 5001
  }
}