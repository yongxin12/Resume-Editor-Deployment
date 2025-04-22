# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/containerengine_node_pool

resource "oci_containerengine_node_pool" "oke-node-pool" {
  # Required
  cluster_id         = oci_containerengine_cluster.oke-cluster.id
  compartment_id     = oci_identity_compartment.tf-compartment.id
  kubernetes_version = "v1.31.1"
  name               = "resume-modifier-node-pool"
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.vcn-private-subnet.id
    }
    size = 2
  }
  node_shape = "VM.Standard.A1.Flex"
  node_shape_config {
    ocpus         = "2"
    memory_in_gbs = "12"
  }

  # Using image Oracle-Linux-7.x-<date>
  # Find image OCID for your region from https://docs.oracle.com/iaas/images/ 
  node_source_details {
    image_id    = "ocid1.image.oc1.ca-toronto-1.aaaaaaaanscnsfrqpjb7df7y63vceo3swr736izoc3tz4abysouktnfkuytq"
    source_type = "image"
  }

  # Optional
  initial_node_labels {
    key   = "name"
    value = "resume-modifier-cluster"
  }
}
