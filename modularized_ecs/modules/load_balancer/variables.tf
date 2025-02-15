# load balancer

variable subnet_ids {}
variable vpc_id {}
variable aws_security_group_id {}

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
