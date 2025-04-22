variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1" # Change to your region
}

variable "tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI user OCID"
  type        = string
}

variable "fingerprint" {
  description = "OCI API key fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API private key"
  type        = string
}

variable "certificate_ocid" {
  description = "OCID of the Certificate Service managed certificate for oci.mintmelon.ca"
  type        = string
  # This can be found in the OCI Console:
  # 1. Go to Identity & Security → Certificates
  # 2. Find the certificate for oci.mintmelon.ca
  # 3. Copy the OCID (starts with ocid1.certificate.oc1...)
}

variable "dns_zone_ocid" {
  description = "OCID of the DNS zone for mintmelon.ca"
  type        = string
  # This can be found in the OCI Console:
  # 1. Go to Networking → DNS Management → Zones
  # 2. Find the zone for mintmelon.ca
  # 3. Copy the OCID (starts with ocid1.dns-zone.oc1...)
}