output "subnet_ids" {
  value = aws_subnet.public[*].id
}

output "aws_security_group_id" {
  value = aws_security_group.allow_web.id
}

output "vpc_id" {
  value = aws_vpc.production_vpc.id
}

output "aws_ecs_cluster_main_id" {
  value = aws_ecs_cluster.main.id
}

output "postgres_username" {
  value = aws_db_instance.postgres.username
}

output "aws_db_instance_postgres_endpoint" {
  value = aws_db_instance.postgres.address
}

output "aws_db_instance_postgres_db_name" {
  value = aws_db_instance.postgres.db_name
}