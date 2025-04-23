# Direct approach using zone OCID from variables
# data "oci_load_balancer_load_balancers" "resume_app_lb" {
#     #Required
#     compartment_id = oci_identity_compartment.tf-compartment.id

#     #Optional
#     detail = "true"
#     display_name = "2331c33d-ef3c-4a97-bde9-23f4d83c7d19"
#     state = "ACTIVE"
# }

# resource "oci_dns_rrset" "resume_app_a_record" {
#   zone_name_or_id = var.dns_zone_ocid
#   domain          = "resume.mintmelon.ca"
#   rtype           = "A"
  
#   depends_on = [data.oci_load_balancer_load_balancers.resume_app_lb]

#   items {
#     domain = "resume.mintmelon.ca"
#     # Using the load balancer's actual IP instead of a hard-coded value
#     rdata  = data.oci_load_balancer_load_balancers.resume_app_lb.load_balancers[0].ip_address_details[0].ip_address
#     # rdata  = ""
#     rtype  = "A"
#     ttl    = 300

#   }
# }

# Output the domain
# output "app_domain" {
#   description = "The domain name for the application"
#   value       = "resume.mintmelon.ca"
# }