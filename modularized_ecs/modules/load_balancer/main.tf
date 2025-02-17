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


resource "aws_lb_target_group" "target_groups" {
  for_each = { for tg in var.lb_target_groups : tg.name => tg }

  name        = each.value.name
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = each.value.type

  health_check {
    path                = "/"
    port                = each.value.port
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_listener" "lb_listeners" {
  for_each = { for listener in var.lb_listeners : listener.name => listener }

  load_balancer_arn = aws_lb.production_lb.arn
  port = each.value.port
  protocol = each.value.protocol

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_groups[each.value.lb_target_group_name].arn
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
    target_group_arn = aws_lb_target_group.target_groups["market-backend-tg"].arn
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


resource "aws_lb_listener_rule" "lb_listener_rules" {
  for_each = { for rule in var.lb_listener_rules : rule.name => rule }

  listener_arn = aws_lb_listener.https_listener.arn
  priority = each.value.priority

  condition {
    path_pattern {
      values = [each.value.path]
    }
  }
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_groups[each.value.lb_target_group_name].arn
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
