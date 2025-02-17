locals {
  task_definitions = [
    {
      name_u   = "market_backend"
      name_h   = "market-backend"
      cpu      = 256
      memory   = 512
      port     = 5001
      protocol = "tcp"
    },
    {
      name_u   = "market_frontend"
      name_h   = "market-frontend"
      cpu      = 256
      memory   = 512
      port     = 3000
      protocol = "tcp"
    },
    {
      name_u   = "editor_backend"
      name_h   = "editor-backend"
      cpu      = 256
      memory   = 512
      port     = 5001
      protocol = "tcp"
      environment = [
        {
          name  = "DATABASE_URL"
          value = "postgresql://${module.network.postgres_username}:postgres@${module.network.aws_db_instance_postgres_endpoint}/${module.network.aws_db_instance_postgres_db_name}"
        },
        {
          name  = "DB_HOST"
          value = module.network.aws_db_instance_postgres_endpoint
        }
      ]
      secrets = [
        {
          name      = "OPENAI_API_KEY"
          valueFrom = "arn:aws:secretsmanager:us-east-2:376129840507:secret:OPENAI_API_KEY-irAH0G:OPENAI_API_KEY::"
        }
      ]
    },
    {
      name_u   = "editor_frontend"
      name_h   = "editor-frontend"
      cpu      = 256
      memory   = 512
      port     = 80
      protocol = "tcp"
    }
  ]
}
