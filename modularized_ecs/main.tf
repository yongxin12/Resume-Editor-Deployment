terraform {
  backend "s3" {
    bucket = "resume-editor-terraform-state-bucket"
    key    = "state/resume-modifier-ecs-state.tfstate"
    region = "us-east-2"
  }
}

module "network" {
  source = "./modules/network"

  vpc_cidr            = "10.0.0.0/16"
  public_subnet_count = 2
  availability_zones  = data.aws_availability_zones.available.names
}

module "security" {
  source = "/modules/security"

  vpc_id = module.network.vpc_id
}

module "iam" {
  source = "./modules/iam"

  secret_arn = "arn:aws:secretsmanager:us-east-2:376129840507:secret:OPENAI_API_KEY-irAH0G"
}

module "ecs_cluster" {
  source = "./modules/ecs-cluster"
}

module "load_balancer" {
  source = "./modules/load-balancer"

  vpc_id          = module.network.vpc_id
  subnets         = module.network.public_subnet_ids
  security_groups = [module.security.alb_security_group_id]
  certificate_arn = "arn:aws:acm:us-east-2:376129840507:certificate/f72942a2-9b55-422c-bb66-0cb93407d547"
}

module "route53" {
  source = "./modules/route53"

  lb_dns_name = module.load_balancer.alb_dns_name
  lb_zone_id  = module.load_balancer.alb_zone_id
  zone_id     = "Z0885993Y0TRG27LPG1N"
  domain_name = "aws.mintmelon.ca"
}

module "market_backend" {
  source = "./modules/ecs-service"

  service_name         = "market-backend"
  cluster_id           = module.ecs_cluster.cluster_id
  task_cpu             = 256
  task_memory          = 512
  container_port       = 5001
  container_image      = "376129840507.dkr.ecr.us-east-2.amazonaws.com/market-backend:latest"
  execution_role_arn   = module.iam.ecs_task_execution_role_arn
  target_group_arn     = module.load_balancer.market_backend_tg_arn
  security_groups      = [module.security.alb_security_group_id]
  subnets              = module.network.public_subnet_ids
  log_group            = "/ecs/market_backend"
}

module "market_frontend" {
  source = "./modules/ecs-service"

  service_name         = "market-frontend"
  cluster_id           = module.ecs_cluster.cluster_id
  task_cpu             = 256
  task_memory          = 512
  container_port       = 3000
  container_image      = "376129840507.dkr.ecr.us-east-2.amazonaws.com/market-frontend:latest"
  execution_role_arn   = module.iam.ecs_task_execution_role_arn
  target_group_arn     = module.load_balancer.market_frontend_tg_arn
  security_groups      = [module.security.alb_security_group_id]
  subnets              = module.network.public_subnet_ids
  log_group            = "/ecs/market_frontend"
}

module "editor_backend" {
  source = "./modules/ecs-service"

  service_name         = "editor-backend"
  cluster_id           = module.ecs_cluster.cluster_id
  task_cpu             = 256
  task_memory          = 512
  container_port       = 5001
  container_image      = "376129840507.dkr.ecr.us-east-2.amazonaws.com/editor-backend:latest"
  execution_role_arn   = module.iam.ecs_task_execution_role_arn
  target_group_arn     = module.load_balancer.editor_backend_tg_arn
  security_groups      = [module.security.alb_security_group_id]
  subnets              = module.network.public_subnet_ids
  log_group            = "/ecs/editor_backend"
  secrets = [
    {
      name      = "OPENAI_API_KEY"
      valueFrom = "arn:aws:secretsmanager:us-east-2:376129840507:secret:OPENAI_API_KEY-irAH0G:OPENAI_API_KEY::"
    }
  ]
}

module "editor_frontend" {
  source = "./modules/ecs-service"

  service_name         = "editor-frontend"
  cluster_id           = module.ecs_cluster.cluster_id
  task_cpu             = 256
  task_memory          = 512
  container_port       = 80
  container_image      = "376129840507.dkr.ecr.us-east-2.amazonaws.com/editor-frontend:latest"
  execution_role_arn   = module.iam.ecs_task_execution_role_arn
  target_group_arn     = module.load_balancer.editor_frontend_tg_arn
  security_groups      = [module.security.alb_security_group_id]
  subnets              = module.network.public_subnet_ids
  log_group            = "/ecs/editor_frontend"
}

data "aws_availability_zones" "available" {
  state = "available"
}