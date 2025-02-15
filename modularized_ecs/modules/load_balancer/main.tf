# Load balancer

# Create load balancer
# Create an ALB
resource "aws_lb" "production_lb" {
  name               = "ecs-production-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.aws_security_group_id]
  subnets            = var.subnet_ids[*] # all subnet

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "market_backend_tg" {
  name        = var.lb_target_group_name_1
  port        = var.lb_target_group_port_1
  protocol    = var.lb_target_group_protocol
  vpc_id      = var.vpc_id
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
  vpc_id      = var.vpc_id
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
  vpc_id      = var.vpc_id
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
  vpc_id      = var.vpc_id
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