variable "registered_domain_name" { type=string }
variable "website_bucket_name" { type=string }
variable "visitor_images_bucket_name" { type=string }
variable "printful_store_id" { type=string }
variable "stripe_public_key" { type=string }

# DISCRETION!
# VARIABLES ABOVE CAN BE SEEN (tf-config.tf)
# VARIABLES BELOW ARE SECRET (terraform.tfvars)

variable "INTERNAL_API_KEY" { 
  type=string 
  sensitive=true 
}
variable "PRINTFUL_API_KEY" { 
  type=string 
  sensitive=true 
}
variable "STRIPE_SECRET_KEY" { 
  type=string 
  sensitive=true 
}
