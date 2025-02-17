# variables.tf
# Input variables
variable s3_region {}
variable s3_bucket {}
variable s3_key {}
variable vpc_cidr_block {}

# # Security group variables
# variable "sg_ingress_rules" {
#   description = "List of security group ingress rules"
#   type = list(object({
#     description = string
#     port        = number
#     protocol    = string
#   }))
# }

variable sg_ingress_description_http {}
variable sg_ingress_port_http {}
variable sg_ingress_description_https {}
variable sg_ingress_port_https {}
variable sg_ingress_protocol {}
variable sg_ingress_description_1 {}
variable sg_ingress_port_1 {}
variable sg_ingress_port_2 {}
variable sg_ingress_port_3 {}
variable sg_ingress_port_4 {}
variable sg_ingress_description_2 {}
variable sg_ingress_description_3 {}
variable sg_ingress_description_4 {}

# ECS cluster
variable ecs_cluster_name {}

# load balancer
# shared
variable lb_target_group_protocol {}
variable lb_target_group_target_type {}
# not shared
variable lb_target_group_name_1 {}
variable lb_target_group_port_1 {}
variable lb_target_group_name_2 {}
variable lb_target_group_port_2 {}
variable lb_target_group_name_3 {}
variable lb_target_group_port_3 {}
variable lb_target_group_name_4 {}
variable lb_target_group_port_4 {}

variable lb_listener_protocol {}
variable lb_listener_port_1 {}
variable lb_listener_port_2 {}
variable lb_listener_port_3 {}
variable lb_listener_port_4 {}

variable lb_listener_rule_path_1 {}
variable lb_listener_rule_priority_1 {}
variable lb_listener_rule_path_2 {}
variable lb_listener_rule_priority_2 {}
variable lb_listener_rule_path_3 {}
variable lb_listener_rule_priority_3 {}
variable lb_listener_rule_path_4 {}
variable lb_listener_rule_priority_4 {}

# route 53
variable route53_record_zone_id {}
variable route53_record_name {}
variable route53_record_type {}
