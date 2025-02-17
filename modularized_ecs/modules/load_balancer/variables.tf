# load balancer

variable "subnet_ids" {}
variable "vpc_id" {}
variable "aws_security_group_id" {}

variable "lb_target_groups" {
  description = "List of target groups"
  type = list(object({
    name     = string
    port     = number
    protocol = string
    type     = string
  }))
}

variable "lb_listeners" {
  description = "List of listeners"
  type = list(object({
    name                 = string
    protocol             = string
    port                 = number
    lb_target_group_name = string
  }))
}

variable "lb_listener_rules" {
  description = "List of listener rules"
  type = list(object({
    name                 = string
    path                 = string
    priority             = number
    lb_target_group_name = string
  }))
}

# route 53
variable "route53_record_zone_id" {}
variable "route53_record_name" {}
variable "route53_record_type" {}
