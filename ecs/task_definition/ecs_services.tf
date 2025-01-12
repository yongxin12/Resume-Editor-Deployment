resource "aws_ecs_service" "ecs_services" {
  for_each             = { for task in var.task_definitions : task.name => task }

  name                 = each.value.name
  cluster              = "arn:aws:ecs:us-east-2:376129840507:cluster/DevCluster"
  task_definition      = aws_ecs_task_definition.multiple_tasks[each.key].arn
  desired_count        = 1
  launch_type          = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0a157ba34a13622ea", "subnet-0aa8487ab7193ca53", "subnet-00adaf98503c1d10a"]
    security_groups  = [aws_security_group.ecs_service_sg[each.key].id]
  }
}
