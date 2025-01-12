output "task_definition_arns" {
  value = { for k, td in aws_ecs_task_definition.multiple_tasks : k => td.arn }
  description = "Task definition ARNs for all tasks"
}

output "security_group_ids" {
  value = { for k, sg in aws_security_group.ecs_service_sg : k => sg.id }
  description = "Security group IDs for all services"
}

