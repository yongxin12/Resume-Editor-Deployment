# # Local variables for NodePort values
# locals {
#   market_frontend_nodeport = 30000  # NodePort for market-frontend
#   market_backend_nodeport = 30001  # NodePort for market-backend
#   editor_frontend_nodeport = 30002  # NodePort for editor-frontend
#   editor_backend_nodeport = 30003  # NodePort for editor-backend
# }

# resource "oci_load_balancer" "resume_app_lb" {
#   compartment_id = oci_identity_compartment.tf-compartment.id
#   display_name   = "resume-modifier-lb"
#   shape          = "flexible"
#   shape_details {
#     minimum_bandwidth_in_mbps = 10
#     maximum_bandwidth_in_mbps = 10
#   }
  
#   subnet_ids = [
#     oci_core_subnet.k8s_api_endpoint_subnet.id  # Using the public subnet
#   ]

#   # Ensure IP is reserved and static
#   is_private = false

#   # Network security rules are managed by security lists and NSGs
#   network_security_group_ids = [
#     oci_core_network_security_group.lb_network_security_group.id
#   ]
# }

# # Keep the existing backend set names but update their configuration
# resource "oci_load_balancer_backend_set" "http_backend_set" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   name             = "http-backend-set"
#   policy           = "ROUND_ROBIN"

#   # This will be the market frontend NodePort (our default service)
#   health_checker {
#     protocol          = "HTTP"
#     port              = local.market_frontend_nodeport
#     url_path          = "/"
#     retries           = 5
#     timeout_in_millis = 5000
#     interval_ms       = 15000
#     return_code       = 200
#   }
# }

# # Keep the existing backend set names but update their configuration
# resource "oci_load_balancer_backend_set" "https_backend_set" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   name             = "https-backend-set"
#   policy           = "ROUND_ROBIN"

#   # This will also be the market frontend NodePort
#   health_checker {
#     protocol          = "HTTP"
#     port              = local.market_frontend_nodeport
#     url_path          = "/"
#     retries           = 5
#     timeout_in_millis = 5000
#     interval_ms       = 15000
#     return_code       = 200
#   }
# }

# # Add new backend sets for other services
# resource "oci_load_balancer_backend_set" "market_backend_set" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   name             = "market-backend-set"
#   policy           = "ROUND_ROBIN"

#   health_checker {
#     protocol          = "HTTP"
#     port              = local.market_backend_nodeport
#     url_path          = "/"
#     retries           = 5
#     timeout_in_millis = 5000
#     interval_ms       = 15000
#     return_code       = 200
#   }
# }

# resource "oci_load_balancer_backend_set" "editor_frontend_set" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   name             = "editor-frontend-set"
#   policy           = "ROUND_ROBIN"

#   health_checker {
#     protocol          = "HTTP"
#     port              = local.editor_frontend_nodeport
#     url_path          = "/"
#     retries           = 5
#     timeout_in_millis = 5000
#     interval_ms       = 15000
#     return_code       = 200
#   }
# }

# resource "oci_load_balancer_backend_set" "editor_backend_set" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   name             = "editor-backend-set"
#   policy           = "ROUND_ROBIN"

#   health_checker {
#     protocol          = "HTTP"
#     port              = local.editor_backend_nodeport
#     url_path          = "/"
#     retries           = 5
#     timeout_in_millis = 5000
#     interval_ms       = 15000
#     return_code       = 200
#   }
# }

# # Update existing path route set - keeping the same resource name
# resource "oci_load_balancer_path_route_set" "app_path_route_set" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   name             = "app-path-routes"
  
#   # Route to market backend API
#   path_routes {
#     backend_set_name = oci_load_balancer_backend_set.market_backend_set.name
#     path             = "/api/job_market"
#     path_match_type {
#       match_type = "PREFIX_MATCH"
#     }
#   }

#   # Route to editor backend API
#   path_routes {
#     backend_set_name = oci_load_balancer_backend_set.editor_backend_set.name
#     path             = "/api/modifier"
#     path_match_type {
#       match_type = "PREFIX_MATCH"
#     }
#   }

#   # Route to editor frontend
#   path_routes {
#     backend_set_name = oci_load_balancer_backend_set.editor_frontend_set.name
#     path             = "/modifier"
#     path_match_type {
#       match_type = "PREFIX_MATCH"
#     }
#   }

#   # Default route to market frontend
#   path_routes {
#     backend_set_name = oci_load_balancer_backend_set.http_backend_set.name
#     path             = "/"
#     path_match_type {
#       match_type = "PREFIX_MATCH"
#     }
#   }
# }

# # Update existing HTTPS path route set - keeping the same resource name
# resource "oci_load_balancer_path_route_set" "https_app_path_route_set" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   name             = "https-app-path-routes"
  
#   # Route to market backend API
#   path_routes {
#     backend_set_name = oci_load_balancer_backend_set.market_backend_set.name
#     path             = "/api/job_market"
#     path_match_type {
#       match_type = "PREFIX_MATCH"
#     }
#   }

#   # Route to editor backend API
#   path_routes {
#     backend_set_name = oci_load_balancer_backend_set.editor_backend_set.name
#     path             = "/api/modifier"
#     path_match_type {
#       match_type = "PREFIX_MATCH"
#     }
#   }

#   # Route to editor frontend
#   path_routes {
#     backend_set_name = oci_load_balancer_backend_set.editor_frontend_set.name
#     path             = "/modifier"
#     path_match_type {
#       match_type = "PREFIX_MATCH"
#     }
#   }

#   # Default route to market frontend
#   path_routes {
#     backend_set_name = oci_load_balancer_backend_set.https_backend_set.name
#     path             = "/"
#     path_match_type {
#       match_type = "PREFIX_MATCH"
#     }
#   }
# }

# # HTTP Listener - redirect to HTTPS
# resource "oci_load_balancer_listener" "http_listener" {
#   load_balancer_id         = oci_load_balancer.resume_app_lb.id
#   name                     = "http-listener"
#   default_backend_set_name = oci_load_balancer_backend_set.http_backend_set.name
#   port                     = 80
#   protocol                 = "HTTP"
  
#   # Add redirection from HTTP to HTTPS
#   rule_set_names = [oci_load_balancer_rule_set.redirect_http_to_https.name]
  
#   # Add path-based routing (only used if not redirected to HTTPS)
#   path_route_set_name = oci_load_balancer_path_route_set.app_path_route_set.name
# }

# # HTTPS Listener with SSL termination
# resource "oci_load_balancer_listener" "https_listener" {
#   load_balancer_id         = oci_load_balancer.resume_app_lb.id
#   name                     = "https-listener"
#   default_backend_set_name = oci_load_balancer_backend_set.https_backend_set.name
#   port                     = 443
#   protocol                 = "HTTP"  # OCI requires HTTP here, even for HTTPS listeners

#   # Add path-based routing for HTTPS
#   path_route_set_name = oci_load_balancer_path_route_set.https_app_path_route_set.name
  
#   # SSL Configuration for terminating HTTPS at the load balancer
#   ssl_configuration {
#     certificate_ids        = [var.certificate_ocid]
#     verify_peer_certificate = false
#     verify_depth            = 5
#     protocols               = ["TLSv1.2"]
#   }
# }

# # Rule set to redirect HTTP to HTTPS
# resource "oci_load_balancer_rule_set" "redirect_http_to_https" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   name             = "redirect_http_to_https"
  
#   items {
#     action = "REDIRECT"
#     redirect_uri {
#       protocol = "HTTPS"
#       port     = 443
#       host     = "{host}"
#       path     = "/{path}"
#       query    = "?{query}"
#     }
#     conditions {
#       attribute_name  = "PATH"
#       attribute_value = "/"
#       operator        = "FORCE_LONGEST_PREFIX_MATCH"
#     }
#     response_code = 301
#   }
# }

# # Add a data source to get the node pool information
# data "oci_containerengine_node_pool" "resume_modifier_node_pool" {
#   node_pool_id = oci_containerengine_node_pool.oke-node-pool.id
# }

# # Output the Load Balancer public IP
# output "load_balancer_ip" {
#   description = "The public IP address of the Load Balancer"
#   value       = oci_load_balancer.resume_app_lb.ip_address_details[0].ip_address
# }

# # Network Security Group for the Load Balancer
# resource "oci_core_network_security_group" "lb_network_security_group" {
#   compartment_id = oci_identity_compartment.tf-compartment.id
#   vcn_id         = module.vcn.vcn_id
#   display_name   = "lb-network-security-group"
# }

# # Allow HTTP traffic to the load balancer
# resource "oci_core_network_security_group_security_rule" "lb_nsg_rule_http_ingress" {
#   network_security_group_id = oci_core_network_security_group.lb_network_security_group.id
#   direction                 = "INGRESS"
#   protocol                  = "6" # TCP
#   source                    = "0.0.0.0/0"
#   source_type               = "CIDR_BLOCK"
#   stateless                 = false
#   tcp_options {
#     destination_port_range {
#       min = 80
#       max = 80
#     }
#   }
# }

# # Allow HTTPS traffic to the load balancer
# resource "oci_core_network_security_group_security_rule" "lb_nsg_rule_https_ingress" {
#   network_security_group_id = oci_core_network_security_group.lb_network_security_group.id
#   direction                 = "INGRESS"
#   protocol                  = "6" # TCP
#   source                    = "0.0.0.0/0"
#   source_type               = "CIDR_BLOCK"
#   stateless                 = false
#   tcp_options {
#     destination_port_range {
#       min = 443
#       max = 443
#     }
#   }
# }

# # Allow egress traffic to all NodePort services
# resource "oci_core_network_security_group_security_rule" "lb_nsg_rule_market_frontend_egress" {
#   network_security_group_id = oci_core_network_security_group.lb_network_security_group.id
#   direction                 = "EGRESS"
#   protocol                  = "6" # TCP
#   destination               = "10.0.0.0/16" # VCN CIDR
#   destination_type          = "CIDR_BLOCK"
#   stateless                 = false
  
#   tcp_options {
#     destination_port_range {
#       min = local.market_frontend_nodeport
#       max = local.market_frontend_nodeport
#     }
#   }
# }

# resource "oci_core_network_security_group_security_rule" "lb_nsg_rule_market_backend_egress" {
#   network_security_group_id = oci_core_network_security_group.lb_network_security_group.id
#   direction                 = "EGRESS"
#   protocol                  = "6" # TCP
#   destination               = "10.0.0.0/16" # VCN CIDR
#   destination_type          = "CIDR_BLOCK"
#   stateless                 = false
  
#   tcp_options {
#     destination_port_range {
#       min = local.market_backend_nodeport
#       max = local.market_backend_nodeport
#     }
#   }
# }

# resource "oci_core_network_security_group_security_rule" "lb_nsg_rule_editor_frontend_egress" {
#   network_security_group_id = oci_core_network_security_group.lb_network_security_group.id
#   direction                 = "EGRESS"
#   protocol                  = "6" # TCP
#   destination               = "10.0.0.0/16" # VCN CIDR
#   destination_type          = "CIDR_BLOCK"
#   stateless                 = false
  
#   tcp_options {
#     destination_port_range {
#       min = local.editor_frontend_nodeport
#       max = local.editor_frontend_nodeport
#     }
#   }
# }

# resource "oci_core_network_security_group_security_rule" "lb_nsg_rule_editor_backend_egress" {
#   network_security_group_id = oci_core_network_security_group.lb_network_security_group.id
#   direction                 = "EGRESS"
#   protocol                  = "6" # TCP
#   destination               = "10.0.0.0/16" # VCN CIDR
#   destination_type          = "CIDR_BLOCK"
#   stateless                 = false
  
#   tcp_options {
#     destination_port_range {
#       min = local.editor_backend_nodeport
#       max = local.editor_backend_nodeport
#     }
#   }
# }

# # Add backends to the market frontend backend set
# resource "oci_load_balancer_backend" "market_frontend_backend_node1" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   backendset_name  = oci_load_balancer_backend_set.http_backend_set.name
#   ip_address       = "10.0.1.185"
#   port             = local.market_frontend_nodeport
#   backup           = false
#   drain            = false
#   offline          = false
#   weight           = 1
# }

# resource "oci_load_balancer_backend" "market_frontend_backend_node2" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   backendset_name  = oci_load_balancer_backend_set.http_backend_set.name
#   ip_address       = "10.0.1.74"
#   port             = local.market_frontend_nodeport
#   backup           = false
#   drain            = false
#   offline          = false
#   weight           = 1
# }

# # Add backends to the https backend set
# resource "oci_load_balancer_backend" "https_backend_node1" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   backendset_name  = oci_load_balancer_backend_set.https_backend_set.name
#   ip_address       = "10.0.1.185"
#   port             = local.market_frontend_nodeport
#   backup           = false
#   drain            = false
#   offline          = false
#   weight           = 1
# }

# resource "oci_load_balancer_backend" "https_backend_node2" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   backendset_name  = oci_load_balancer_backend_set.https_backend_set.name
#   ip_address       = "10.0.1.74"
#   port             = local.market_frontend_nodeport
#   backup           = false
#   drain            = false
#   offline          = false
#   weight           = 1
# }

# # Add backends to the market backend backend set
# resource "oci_load_balancer_backend" "market_backend_backend_node1" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   backendset_name  = oci_load_balancer_backend_set.market_backend_set.name
#   ip_address       = "10.0.1.185"
#   port             = local.market_backend_nodeport
#   backup           = false
#   drain            = false
#   offline          = false
#   weight           = 1
# }

# resource "oci_load_balancer_backend" "market_backend_backend_node2" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   backendset_name  = oci_load_balancer_backend_set.market_backend_set.name
#   ip_address       = "10.0.1.74"
#   port             = local.market_backend_nodeport
#   backup           = false
#   drain            = false
#   offline          = false
#   weight           = 1
# }

# # Add backends to the editor frontend backend set
# resource "oci_load_balancer_backend" "editor_frontend_backend_node1" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   backendset_name  = oci_load_balancer_backend_set.editor_frontend_set.name
#   ip_address       = "10.0.1.185"
#   port             = local.editor_frontend_nodeport
#   backup           = false
#   drain            = false
#   offline          = false
#   weight           = 1
# }

# resource "oci_load_balancer_backend" "editor_frontend_backend_node2" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   backendset_name  = oci_load_balancer_backend_set.editor_frontend_set.name
#   ip_address       = "10.0.1.74"
#   port             = local.editor_frontend_nodeport
#   backup           = false
#   drain            = false
#   offline          = false
#   weight           = 1
# }

# # Add backends to the editor backend backend set
# resource "oci_load_balancer_backend" "editor_backend_backend_node1" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   backendset_name  = oci_load_balancer_backend_set.editor_backend_set.name
#   ip_address       = "10.0.1.185"
#   port             = local.editor_backend_nodeport
#   backup           = false
#   drain            = false
#   offline          = false
#   weight           = 1
# }

# resource "oci_load_balancer_backend" "editor_backend_backend_node2" {
#   load_balancer_id = oci_load_balancer.resume_app_lb.id
#   backendset_name  = oci_load_balancer_backend_set.editor_backend_set.name
#   ip_address       = "10.0.1.74"
#   port             = local.editor_backend_nodeport
#   backup           = false
#   drain            = false
#   offline          = false
#   weight           = 1
# }

# # Create a separate ingress security rule for NodePort traffic
# resource "oci_core_network_security_group_security_rule" "allow_nodeport_traffic" {
#   network_security_group_id = oci_core_network_security_group.lb_network_security_group.id
#   direction                 = "INGRESS"
#   protocol                  = "6" # TCP
#   source                    = "10.0.0.0/16" # VCN CIDR
#   source_type               = "CIDR_BLOCK"
#   stateless                 = false
  
#   tcp_options {
#     destination_port_range {
#       min = 30000
#       max = 32767
#     }
#   }
# } 