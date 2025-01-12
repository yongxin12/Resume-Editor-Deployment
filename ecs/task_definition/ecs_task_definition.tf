variable "task_definitions" {
  description = "List of task definitions with different configurations"
  type = list(object({
    name           = string
    family         = string
    image_url      = string
    container_port = number
    host_port      = number
    cpu            = number
    memory         = number
    awslogs_group  = string
  }))
}

resource "aws_ecs_task_definition" "multiple_tasks" {
  
  for_each                 = { for task in var.task_definitions : task.name => task }
  family                   = each.value.family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = "arn:aws:iam::376129840507:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = each.value.name
      image     = each.value.image_url
      cpu       = each.value.cpu
      essential = true

      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.host_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = each.value.awslogs_group
          "awslogs-region"        = "us-east-2"
          "max-buffer-size"       = "25m"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}
