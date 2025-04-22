# Outputs for compartment
# Output the "list" of all availability domains.
# output "all-availability-domains-in-your-tenancy" {
#   value = data.oci_identity_availability_domains.ads.availability_domains
# }
# output "compartment-name" {
#   value = oci_identity_compartment.tf-compartment.name
# }

# output "compartment-OCID" {
#   value = oci_identity_compartment.tf-compartment.id
# }

# # Outputs for compute instance
# output "public-ip-for-compute-instance" {
#   value = oci_core_instance.ubuntu_instance.public_ip
# }


# output "instance-name" {
#   value = oci_core_instance.ubuntu_instance.display_name
# }

# output "instance-OCID" {
#   value = oci_core_instance.ubuntu_instance.id
# }

# output "instance-region" {
#   value = oci_core_instance.ubuntu_instance.region
# }

# output "instance-shape" {
#   value = oci_core_instance.ubuntu_instance.shape
# }

# output "instance-state" {
#   value = oci_core_instance.ubuntu_instance.state
# }

# output "instance-OCPUs" {
#   value = oci_core_instance.ubuntu_instance.shape_config[0].ocpus
# }

# output "instance-memory-in-GBs" {
#   value = oci_core_instance.ubuntu_instance.shape_config[0].memory_in_gbs
# }

# output "time-created" {
#   value = oci_core_instance.ubuntu_instance.time_created
# }


# Outputs for private subnet

# output "private-subnet-name" {
#   value = oci_core_subnet.vcn-private-subnet.display_name
# }
# output "private-subnet-OCID" {
#   value = oci_core_subnet.vcn-private-subnet.id
# }


# Outputs for private security list

# output "private-security-list-name" {
#   value = oci_core_security_list.private-security-list.display_name
# }
# output "private-security-list-OCID" {
#   value = oci_core_security_list.private-security-list.id
# }

# Outputs for public security list

output "k8s-api-endpoint-security-list-name" {
  value = oci_core_security_list.k8s_api_endpoint_security_list.display_name
}
output "k8s-api-endpoint-security-list-OCID" {
  value = oci_core_security_list.k8s_api_endpoint_security_list.id
}