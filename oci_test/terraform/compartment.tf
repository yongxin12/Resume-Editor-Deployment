resource "oci_identity_compartment" "tf-compartment" {
  # Required
  compartment_id = var.tenancy_ocid
  description    = "Compartment for Terraform resources."
  name           = "resume-modifier-compartment"
}

# Source from https://registry.terraform.io/modules/oracle-terraform-modules/vcn/oci/
module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.6.0"
  # insert the 1 required variable here

  # Required Inputs
  compartment_id = oci_identity_compartment.tf-compartment.id

  # Optional Inputs 
  region = var.region

  # Changing the following default values
  vcn_name                = "resume-app-vcn"
  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true

  # Using the following default values
  # vcn_dns_label = "vcnmodule"
  # vcn_cidrs = ["10.0.0.0/16"]
}

resource "oci_core_subnet" "vcn-private-subnet" {

  # Required
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = "10.0.1.0/24"

  # Optional
  # Caution: For the route table id, use module.vcn.nat_route_id.
  # Do not use module.vcn.nat_gateway_id, because it is the OCID for the gateway and not the route table.
  route_table_id    = module.vcn.nat_route_id
  security_list_ids = [oci_core_security_list.private-security-list.id]
  display_name      = "private-subnet"
}

resource "oci_core_security_list" "private-security-list" {

  # Required
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = module.vcn.vcn_id

  # Optional
  display_name = "security-list-for-private-subnet"
  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
    protocol = "6"
    tcp_options {
      min = 22
      max = 22
    }
  }
  
  # # Allow UDP VXLAN traffic between nodes for Flannel
  # ingress_security_rules {
  #   stateless   = false
  #   source      = "10.0.0.0/16"  # VCN CIDR
  #   source_type = "CIDR_BLOCK"
  #   protocol    = "17"  # UDP
  #   udp_options {
  #     min = 14789
  #     max = 14789
  #   }
  # }
  
  # Allow all pod traffic between nodes
  ingress_security_rules {
    stateless   = false
    source      = "10.244.0.0/16"  # Pod CIDR
    source_type = "CIDR_BLOCK"
    protocol    = "all"  # All protocols
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Allow from any source (including load balancer)
    source_type = "CIDR_BLOCK"
    protocol    = "6" # TCP

    tcp_options {
      min = 5001
      max = 5001
    }
  }
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Allow from any source (including load balancer)
    source_type = "CIDR_BLOCK"
    protocol    = "6" # TCP

    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Allow from any source (including load balancer)
    source_type = "CIDR_BLOCK"
    protocol    = "6" # TCP

    tcp_options {
      min = 443
      max = 443
    }
  }
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Allow from any source (including load balancer)
    source_type = "CIDR_BLOCK"
    protocol    = "6" # TCP
    tcp_options {
      min = 8443
      max = 8443
    }
  }

    # Allow UDP VXLAN traffic between nodes for Flannel
    ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Allow from any source (including load balancer)
    source_type = "CIDR_BLOCK"
    protocol    = "17" # UDP
    udp_options {
      min = 8472
      max = 8472
    }
  }
  # Allow UDP VXLAN traffic between nodes for Flannel
  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"  # VCN CIDR
    source_type = "CIDR_BLOCK"
    protocol    = "17"  # UDP
    udp_options {
      min = 14789
      max = 14789
    }
  }

   # Allow all pod traffic between nodes
  ingress_security_rules {
    stateless   = false
    source      = "10.244.0.0/16"  # Pod CIDR
    source_type = "CIDR_BLOCK"
    protocol    = "all"  # All protocols
  }
  

  ingress_security_rules {
    protocol    = "6" 
    source      = "10.0.0.0/24" 
    source_type = "CIDR_BLOCK" 
    stateless   = false 
            # (1 unchanged attribute hidden)

    tcp_options {
      min = 10256
      max = 10256
    }
  }


  # Add NodePort range ingress rule to allow traffic to Kubernetes NodePort services
  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/24" # Allow from any source (including load balancer)
    source_type = "CIDR_BLOCK"
    protocol    = "6" # TCP

    tcp_options {
      min = 30000
      max = 32767
    }
  }

  
}

resource "oci_core_subnet" "k8s_api_endpoint_subnet" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = "10.0.0.0/24" # Example CIDR

  # Optional
  route_table_id    = module.vcn.ig_route_id
  security_list_ids = [oci_core_security_list.k8s_api_endpoint_security_list.id]
  display_name      = "k8s-api-endpoint-subnet"
}

resource "oci_core_security_list" "k8s_api_endpoint_security_list" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "api-endpoint-security-list"




  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }


  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 12250
      max = 12250
    }
  }
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
    protocol = "6"
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
    protocol = "6"
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
    protocol = "6"
    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
    protocol = "6"
    tcp_options {
      min = 5001
      max = 5001
    }
  }


  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
    protocol = "1"

    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
    protocol = "1"

    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3
    }
  }

  # Add NodePort range ingress rule to allow traffic to Kubernetes NodePort services
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0" # Allow from any source (including load balancer)
    source_type = "CIDR_BLOCK"
    protocol    = "6" # TCP

    tcp_options {
      min = 30000
      max = 32767
    }
  }

  lifecycle {
    ignore_changes = [
      ingress_security_rules,
      egress_security_rules
    ]
  }

  # Add other rules...
}

resource "oci_core_network_security_group" "k8s_api_endpoint_nsg" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "k8s-api-endpoint-nsg"
}
resource "oci_core_network_security_group_security_rule" "k8s_api_endpoint_nsg_rule_http" {
  network_security_group_id = oci_core_network_security_group.k8s_api_endpoint_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

# Add HTTPS ingress rule for port 443
resource "oci_core_network_security_group_security_rule" "k8s_api_endpoint_nsg_rule_https" {
  network_security_group_id = oci_core_network_security_group.k8s_api_endpoint_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# Add HTTP NodePort ingress rule
resource "oci_core_network_security_group_security_rule" "k8s_api_endpoint_nsg_rule_http_nodeport" {
  network_security_group_id = oci_core_network_security_group.k8s_api_endpoint_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 30000
      max = 32767
    }
  }
}

resource "oci_core_network_security_group_security_rule" "k8s_api_endpoint_nsg_rule_backend_port" {
  network_security_group_id = oci_core_network_security_group.k8s_api_endpoint_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 5001
      max = 5001
    }
  }
}





# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/containerengine_cluster

resource "oci_containerengine_cluster" "oke-cluster" {
  # Required
  compartment_id     = oci_identity_compartment.tf-compartment.id
  kubernetes_version = "v1.31.1"
  name               = "resume-modifier-cluster"
  vcn_id             = module.vcn.vcn_id


  endpoint_config {

    #Optional
    is_public_ip_enabled = true                                                      # or false for private endpoint
    nsg_ids              = [oci_core_network_security_group.k8s_api_endpoint_nsg.id] # Optional: Network Security Groups
    subnet_id            = oci_core_subnet.k8s_api_endpoint_subnet.id
  }
  # Optional
  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.k8s_api_endpoint_subnet.id]
  }
}

