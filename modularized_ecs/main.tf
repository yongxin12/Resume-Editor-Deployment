terraform {
  backend "s3" {
    bucket = "resume-editor-terraform-state-bucket"
    key    = "state/resume-modifier-ecs-state.tfstate"
    region = "us-east-2"
  }
}

module "iam" {
  source = "./modules/iam"
}

module "network" {
  source = "./modules/network"

  vpc_cidr_block   = var.vpc_cidr_block
  sg_ingress_rules = var.sg_ingress_rules
  ecs_cluster_name = var.ecs_cluster_name
}

module "iam" {
  source = "./modules/iam"
}

module "load_balancer" {
  source = "./modules/load_balancer"

  aws_security_group_id = module.network.aws_security_group_id
  subnet_ids = module.network.subnet_ids[*]
  vpc_id     = module.network.vpc_id


  route53_record_zone_id      = var.route53_record_zone_id
  route53_record_name         = var.route53_record_name
  route53_record_type         = var.route53_record_type
  lb_target_group_protocol    = var.lb_target_group_protocol
  lb_target_group_target_type = var.lb_target_group_target_type
  # not shared
  lb_target_group_name_1 = var.lb_target_group_name_1
  lb_target_group_port_1 = var.lb_target_group_port_1
  lb_target_group_name_2 = var.lb_target_group_name_2
  lb_target_group_port_2 = var.lb_target_group_port_2
  lb_target_group_name_3 = var.lb_target_group_name_3
  lb_target_group_port_3 = var.lb_target_group_port_3
  lb_target_group_name_4 = var.lb_target_group_name_4
  lb_target_group_port_4 = var.lb_target_group_port_4

  lb_listener_protocol = var.lb_listener_protocol
  lb_listener_port_1   = var.lb_listener_port_1
  lb_listener_port_2   = var.lb_listener_port_2
  lb_listener_port_3   = var.lb_listener_port_3
  lb_listener_port_4   = var.lb_listener_port_4

  lb_listener_rule_path_1     = var.lb_listener_rule_path_1
  lb_listener_rule_priority_1 = var.lb_listener_rule_priority_1
  lb_listener_rule_path_2     = var.lb_listener_rule_path_2
  lb_listener_rule_priority_2 = var.lb_listener_rule_priority_2
  lb_listener_rule_path_3     = var.lb_listener_rule_path_3
  lb_listener_rule_priority_3 = var.lb_listener_rule_priority_3
  lb_listener_rule_path_4     = var.lb_listener_rule_path_4
  lb_listener_rule_priority_4 = var.lb_listener_rule_priority_4

}


# resource "aws_ecs_task_definition" "market_backend" {

#   family                   = "market_backend_family"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = 256
#   memory                   = 512
#   execution_role_arn       = module.iam.ecs_task_execution_role_arn

#   container_definitions = jsonencode([
#     {
#       name      = "market_backend"
#       image     = "376129840507.dkr.ecr.us-east-2.amazonaws.com/market-backend:latest"
#       cpu       = 256
#       essential = true

#       portMappings = [
#         {
#           containerPort = 5001
#           hostPort      = 5001
#           protocol      = "tcp"
#         }
#       ]

#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           "awslogs-group"         = "/ecs/market_backend"
#           "awslogs-region"        = "us-east-2"
#           "max-buffer-size"       = "25m"
#           "awslogs-stream-prefix" = "ecs"
#         }
#       }
#     }
#   ])
# }

# resource "aws_ecs_task_definition" "market_frontend" {

#   family                   = "market_frontend_family"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = 256
#   memory                   = 512
#   execution_role_arn       = module.iam.ecs_task_execution_role_arn

#   container_definitions = jsonencode([
#     {
#       name      = "market_frontend"
#       image     = "376129840507.dkr.ecr.us-east-2.amazonaws.com/market-frontend:latest"
#       cpu       = 256
#       essential = true

#       portMappings = [
#         {
#           containerPort = 3000
#           hostPort      = 3000
#           protocol      = "tcp"
#         }
#       ]

#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           "awslogs-group"         = "/ecs/market_frontend"
#           "awslogs-region"        = "us-east-2"
#           "max-buffer-size"       = "25m"
#           "awslogs-stream-prefix" = "ecs"
#         }
#       }
#     }
#   ])
# }

# resource "aws_ecs_task_definition" "editor_frontend" {

#   family                   = "editor_frontend_family"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = 256
#   memory                   = 512
#   execution_role_arn       = module.iam.ecs_task_execution_role_arn

#   container_definitions = jsonencode([
#     {
#       name      = "editor_frontend"
#       image     = "376129840507.dkr.ecr.us-east-2.amazonaws.com/editor-frontend:latest"
#       cpu       = 256
#       essential = true

#       portMappings = [
#         {
#           containerPort = 80
#           hostPort      = 80
#           protocol      = "tcp"
#         }
#       ]

#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           "awslogs-group"         = "/ecs/editor_frontend"
#           "awslogs-region"        = "us-east-2"
#           "max-buffer-size"       = "25m"
#           "awslogs-stream-prefix" = "ecs"
#         }
#       }
#     }
#   ])
# }


# resource "aws_ecs_service" "frontend_service" {
#   name            = "market-frontend-service"
#   cluster         = module.network.aws_ecs_cluster_main_id
#   task_definition = aws_ecs_task_definition.market_frontend.arn
#   desired_count   = 2
#   launch_type     = "FARGATE"
#   network_configuration {
#     subnets          = module.network.subnet_ids
#     security_groups  = [module.network.aws_security_group_id]
#     assign_public_ip = true
#   }
#   load_balancer {
#     target_group_arn = module.load_balancer.market_frontend_tg_arn
#     container_name   = "market_frontend"
#     container_port   = 3000
#   }
# }

# resource "aws_ecs_service" "backend_service" {
#   name            = "market-backend-service"
#   cluster         = module.network.aws_ecs_cluster_main_id
#   task_definition = aws_ecs_task_definition.market_backend.arn
#   desired_count   = 2
#   launch_type     = "FARGATE"
#   network_configuration {
#     subnets          = module.network.subnet_ids
#     security_groups  = [module.network.aws_security_group_id]
#     assign_public_ip = true
#   }
#   load_balancer {
#     target_group_arn = module.load_balancer.market_backend_tg_arn
#     container_name   = "market_backend"
#     container_port   = 5001
#   }
# }


# resource "aws_ecs_service" "editor_frontend_service" {
#   name            = "editor-frontend-service"
#   cluster         = module.network.aws_ecs_cluster_main_id
#   task_definition = aws_ecs_task_definition.editor_frontend.arn
#   desired_count   = 2
#   launch_type     = "FARGATE"
#   network_configuration {
#     subnets          = module.network.subnet_ids
#     security_groups  = [aws_security_group.allow_web.id]
#     assign_public_ip = true
#   }
#   load_balancer {
#     target_group_arn = module.load_balancer.editor_frontend_tg
#     container_name   = "editor_frontend"
#     container_port   = 80
#   }
# }



resource "aws_ecs_task_definition" "editor_backend" {

  family                   = "editor_backend_family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = module.iam.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "editor_backend"
      image     = "376129840507.dkr.ecr.us-east-2.amazonaws.com/editor-backend:latest"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 5001
          hostPort      = 5001
          protocol      = "tcp"
        }
      ]
      # hardcoding arn
      # plain text
      # secrets = [
      #   {
      #     name      = "OPENAI_API_KEY"
      #     valueFrom = "arn:aws:secretsmanager:us-east-2:376129840507:secret:OPENAI_API_KEY-irAH0G"
      #   }
      # ]
      environment = [
        {
          name  = "DATABASE_URL"
          value = "postgresql://${module.network.postgres_username}:postgres@${module.network.aws_db_instance_postgres_endpoint}/${module.network.aws_db_instance_postgres_db_name}"
        },
        {
          name  = "DB_HOST",
            value = "${module.network.aws_db_instance_postgres_endpoint}"
        }
      ]

      secrets = [
        {
          name      = "OPENAI_API_KEY"
          valueFrom = "arn:aws:secretsmanager:us-east-2:376129840507:secret:OPENAI_API_KEY-irAH0G:OPENAI_API_KEY::"
        }
      ]


      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/editor_backend"
          "awslogs-region"        = "us-east-2"
          "max-buffer-size"       = "25m"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }

  ])
}

resource "aws_ecs_service" "editor_backend_service" {
  name            = "editor-backend-service"
  cluster         = module.network.aws_ecs_cluster_main_id
  task_definition = aws_ecs_task_definition.editor_backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.network.subnet_ids
    security_groups  = [module.network.aws_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = module.load_balancer.editor_backend_tg_arn
    container_name   = "editor_backend"
    container_port   = 5001
  }
}

output "aws_db_instance_postgres_endpoint" {
  value = module.network.aws_db_instance_postgres_endpoint
}

