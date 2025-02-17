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


module "load_balancer" {
  source = "./modules/load_balancer"

  aws_security_group_id = module.network.aws_security_group_id
  subnet_ids            = module.network.subnet_ids[*]
  vpc_id                = module.network.vpc_id

  lb_target_groups  = var.lb_target_groups
  lb_listener_rules = var.lb_listener_rules
  lb_listeners      = var.lb_listeners

  route53_record_zone_id = var.route53_record_zone_id
  route53_record_name    = var.route53_record_name
  route53_record_type    = var.route53_record_type
}

resource "aws_ecs_task_definition" "task_definitions" {
  for_each = { for td in local.task_definitions : td.name_u => td }

  family                   = "${each.value.name_u}_family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = module.iam.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "${each.value.name_u}"
      image     = "${var.image_base_url}${each.value.name_h}:latest"
      cpu       = each.value.cpu
      memory    = each.value.memory
      essential = true

      portMappings = [{
        containerPort = each.value.port
        hostPort      = each.value.port
        protocol      = each.value.protocol
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${each.value.name_u}"
          "awslogs-region"        = "us-east-2"
          "max-buffer-size"       = "25m"
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = can(each.value.environment) ? each.value.environment : []
      secrets     = can(each.value.secrets) ? each.value.secrets : []
    }
  ])
}

resource "aws_ecs_service" "ecs_services" {
  for_each = { for td in local.task_definitions : td.name_u => td }

  name = "${each.value.name_h}-service"
  cluster = module.network.aws_ecs_cluster_main_id
  task_definition = aws_ecs_task_definition.task_definitions[each.value.name_u].arn
  desired_count = 2
  launch_type = "FARGATE"

  network_configuration {
    subnets = module.network.subnet_ids
    security_groups = [module.network.aws_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = module.load_balancer.target_group_arns["${each.value.name_h}-tg"]
    container_name = each.value.name_u
    container_port = each.value.port
  }
  
}

output "aws_db_instance_postgres_endpoint" {
  value = module.network.aws_db_instance_postgres_endpoint
}

