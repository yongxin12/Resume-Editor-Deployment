# Load balancer

# Create load balancer
# Create an ALB
resource "aws_lb" "production_lb" {
  name               = "ecs-production-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = aws_subnet.public[*].id          # all subnet

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "backend-tg"
  port        = 5001
  protocol    = "HTTP"
  vpc_id      = aws_vpc.production_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = 5001
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.production_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = 3000
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}



resource "aws_lb_listener" "backend_lb_listener" {
  load_balancer_arn = aws_lb.production_lb.arn
  port              = "5001"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

resource "aws_lb_listener" "frontend_lb_listener" {
  load_balancer_arn = aws_lb.production_lb.arn
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}


output "frontend_target_group_arn" {
  value = aws_lb_target_group.frontend_tg.arn
}

output "main_target_group_arn" {
  value = aws_lb_target_group.backend_tg.arn
}
