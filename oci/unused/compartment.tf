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


# # Public Subnet
# resource "oci_core_subnet" "public_subnet" {
#     compartment_id = oci_identity_compartment.tf-compartment.id
#     vcn_id = oci_core_vcn.resume_app_vcn.id
#     cidr_block = "10.0.0.0/24"
#     display_name = "public-subnet"
#     prohibit_public_ip_on_vnic = false
# }

# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet

# # Private Subnet
# resource "oci_core_subnet" "private_subnet" {
#     compartment_id = oci_identity_compartment.tf-compartment.id
#     vcn_id = oci_core_vcn.resume_app_vcn.id
#     cidr_block = "10.0.1.0/24"
#     display_name = "private-subnet"
#     prohibit_public_ip_on_vnic = true
# }

# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet

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

  # Add other rules...
}

# resource "oci_core_subnet" "vcn-public-subnet" {

#   # Required
#   compartment_id = oci_identity_compartment.tf-compartment.id
#   vcn_id         = module.vcn.vcn_id
#   cidr_block     = "10.0.0.0/24"

#   # Optional
#   route_table_id    = module.vcn.ig_route_id
#   security_list_ids = [oci_core_security_list.public-security-list.id]
#   display_name      = "public-subnet"
# }





# resource "oci_core_internet_gateway" "resume_app_igw" {
#   compartment_id = oci_identity_compartment.tf-compartment.id
#   display_name   = "resume-app-igw"
#   vcn_id         = oci_core_vcn.resume_app_vcn.id
# } 

# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list



# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list

# resource "oci_core_security_list" "public-security-list" {

#   # Required
#   compartment_id = oci_identity_compartment.tf-compartment.id
#   vcn_id         = module.vcn.vcn_id

#   # Optional
#   display_name = "security-list-for-public-subnet"

#   egress_security_rules {
#     stateless        = false
#     destination      = "0.0.0.0/0"
#     destination_type = "CIDR_BLOCK"
#     protocol         = "all"
#   }

#   ingress_security_rules {
#     stateless   = false
#     source      = "0.0.0.0/0"
#     source_type = "CIDR_BLOCK"
#     # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
#     protocol = "6"
#     tcp_options {
#       min = 22
#       max = 22
#     }
#   }
#   ingress_security_rules {
#     stateless   = false
#     source      = "0.0.0.0/0"
#     source_type = "CIDR_BLOCK"
#     # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
#     protocol = "1"

#     # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
#     icmp_options {
#       type = 3
#       code = 4
#     }
#   }

#   ingress_security_rules {
#     stateless   = false
#     source      = "10.0.0.0/16"
#     source_type = "CIDR_BLOCK"
#     # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
#     protocol = "1"

#     # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
#     icmp_options {
#       type = 3
#     }
#   }
# }



# resource "oci_identity_policy" "oke_policy" {
#   name           = "oke-policy"
#   description    = "Policy for OKE cluster management"
#   compartment_id = var.tenancy_ocid # Use tenancy OCID for tenancy-wide access

#   statements = [
#     # Allow service cluster-kube-system to manage clusters in compartment
#     "Allow service OKE to manage all-resources in compartment id ${oci_identity_compartment.tf-compartment.id}",

#     # Policies for cluster creation and management
#     "Allow group Administrators to manage cluster-family in compartment id ${oci_identity_compartment.tf-compartment.id}",
#     "Allow group Administrators to manage virtual-network-family in compartment id ${oci_identity_compartment.tf-compartment.id}",
#     "Allow group Administrators to manage instance-family in compartment id ${oci_identity_compartment.tf-compartment.id}",
#     "Allow group Administrators to manage load-balancers in compartment id ${oci_identity_compartment.tf-compartment.id}",

#     # Policies for pulling images from OCIR (if needed)
#     "Allow service OKE to read repos in compartment id ${oci_identity_compartment.tf-compartment.id}",

#     # Additional policies for logging/monitoring
#     "Allow service OKE to manage log-groups in compartment id ${oci_identity_compartment.tf-compartment.id}",
#     "Allow service OKE to manage log-content in compartment id ${oci_identity_compartment.tf-compartment.id}",
#     "Allow service OKE to manage ons-topics in compartment id ${oci_identity_compartment.tf-compartment.id}",
#     "Allow service OKE to manage metrics in compartment id ${oci_identity_compartment.tf-compartment.id}"
#   ]
# }

resource "oci_core_network_security_group" "k8s_api_endpoint_nsg" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "k8s-api-endpoint-nsg"
}

resource "oci_core_network_security_group_security_rule" "k8s_api_endpoint_nsg_rule_ingress" {
  network_security_group_id = oci_core_network_security_group.k8s_api_endpoint_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

# Add HTTP ingress rule for port 80
resource "oci_core_network_security_group_security_rule" "k8s_api_endpoint_nsg_rule_http" {
  network_security_group_id = oci_core_network_security_group.k8s_api_endpoint_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  
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
  
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# Add NodePort range for ingress controller
resource "oci_core_network_security_group_security_rule" "k8s_api_endpoint_nsg_rule_nodeport" {
  network_security_group_id = oci_core_network_security_group.k8s_api_endpoint_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  
  tcp_options {
    destination_port_range {
      min = 30000
      max = 32767
    }
  }
}

# Allow Pod-to-Pod communication across nodes
resource "oci_core_network_security_group_security_rule" "k8s_api_endpoint_nsg_rule_pod_network" {
  network_security_group_id = oci_core_network_security_group.k8s_api_endpoint_nsg.id
  direction                 = "INGRESS"
  protocol                  = "all" # All protocols
  
  source                    = "10.244.0.0/16" # Pod CIDR
  source_type               = "CIDR_BLOCK"
}

# Allow egress traffic for pod network
resource "oci_core_network_security_group_security_rule" "k8s_api_endpoint_nsg_rule_pod_network_egress" {
  network_security_group_id = oci_core_network_security_group.k8s_api_endpoint_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all" # All protocols
  
  destination               = "10.244.0.0/16" # Pod CIDR
  destination_type          = "CIDR_BLOCK"
}

# Allow egress traffic to the internet
resource "oci_core_network_security_group_security_rule" "k8s_api_endpoint_nsg_rule_internet_egress" {
  network_security_group_id = oci_core_network_security_group.k8s_api_endpoint_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all" # All protocols
  
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

# Specific egress rule for Let's Encrypt ACME servers
resource "oci_core_network_security_group_security_rule" "k8s_api_endpoint_nsg_rule_letsencrypt_egress" {
  network_security_group_id = oci_core_network_security_group.k8s_api_endpoint_nsg.id
  direction                 = "EGRESS"
  protocol                  = "6" # TCP
  
  destination               = "0.0.0.0/0" # Can be restricted to Let's Encrypt IP ranges if needed
  destination_type          = "CIDR_BLOCK"
  
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }

  description = "Allow outbound HTTPS traffic to Let's Encrypt ACME servers"
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


# resource "oci_core_instance" "ubuntu_instance" {
#   # Required
#   availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
#   compartment_id      = oci_identity_compartment.tf-compartment.id
#   shape               = "VM.Standard.E2.1.Micro"
#   shape_config {
#     ocpus         = "1"
#     memory_in_gbs = "1"
#   }
#   source_details {
#     source_id   = "ocid1.image.oc1.ca-toronto-1.aaaaaaaadtwzeffczkghs325xbzeocp4i7ghpeims5insf6a65kxcpmk4bwq"
#     source_type = "image"
#   }

#   # Optional
#   display_name = "playground-instance"
#   create_vnic_details {
#     assign_public_ip = true
#     subnet_id        = oci_core_subnet.vcn-public-subnet.id
#   }
#   metadata = {
#     ssh_authorized_keys = file("/home/rex/project/resume-editor/deployment/oci_test/id_rsa.pub")
#   }
#   preserve_boot_volume = false
# }


