variable vpc_cidr_block {}


# Security group variables
variable "sg_ingress_rules" {
  description = "List of security group ingress rules"
  type = list(object({
    description = string
    port        = number
    protocol    = string
  }))
}

# ECS cluster
variable ecs_cluster_name {}