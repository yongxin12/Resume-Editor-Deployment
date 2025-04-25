terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=4.67.3"
    }
  }
  required_version = ">= 1.0.0"
}

# # (Terraform version >= 1.6.4)
# terraform {
#   backend "s3" {
#     bucket                    = "bucket-20250424-2214"  #"terraform-states"
#     region                    = "ca-toronto-1"
#     key                       = "tf.tfstate"
#     skip_region_validation      = true
#     skip_credentials_validation = true
#     skip_requesting_account_id  = true
#     use_path_style              = true
#     skip_s3_checksum            = true
#     skip_metadata_api_check = true
#     endpoints = {
#       # s3 = "https://<namespace>.compat.objectstorage.<region>.oraclecloud.com"
#       s3 = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/Qzv9fgQfASxJ0Xw9-gcL0U9kJEMtOCp0Hzbll6XkpMAKJ2dKo7NyjK7U3-hASQuK/n/yztdqx0npeqw/b/bucket-20250424-2214/o/"
#     }
#   }
# }

terraform {
  backend "http" {
    update_method = "PUT"
    address       = "https://objectstorage.ca-toronto-1.oraclecloud.com/p/Qzv9fgQfASxJ0Xw9-gcL0U9kJEMtOCp0Hzbll6XkpMAKJ2dKo7NyjK7U3-hASQuK/n/yztdqx0npeqw/b/bucket-20250424-2214/o/terraform.tfstate"
  }
}