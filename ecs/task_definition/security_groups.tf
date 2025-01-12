resource "aws_security_group" "ecs_service_sg" {
  for_each = { for task in var.task_definitions : task.name => task }

  name        = "ecs-service-sg-${each.key}"
  description = "Security group for ECS service ${each.key}"
  vpc_id      = "vpc-025dec56f1a624242"

  ingress {
    description      = "Allow TCP traffic for the host port"
    from_port        = each.value.host_port
    to_port          = each.value.host_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  lifecycle {
    prevent_destroy = true
  }
}
