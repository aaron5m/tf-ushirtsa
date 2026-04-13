# TERRAFORM GROUP PERMISSIONS

resource "aws_iam_group_policy_attachment" "terraform_admin" {
  group      = "terraform"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# TERRAFORM SETUP BUCKET

terraform {
  backend "s3" {
    bucket = "tfdev-bucket-x0y0"
    key    = "state/terraform.tfstate"
    region = "us-east-2"
  }
}

# PROVIDER

provider "aws" {
  region = "us-east-2"
}

# SSL CERTIFICATION PROVIDER

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1" # Required for ACM/CloudFront
}

# DOMAIN

resource "aws_route53_zone" "main" {
  name                      = var.registered_domain_name
}

# SSL CERTIFICATION

resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = var.registered_domain_name
  validation_method = "DNS"
  subject_alternative_names = ["www.${var.registered_domain_name}"]

  lifecycle {
    create_before_destroy = true
  }
}

# DNS VALIDATION

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# DNS CONFIRMATION

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# OUTPUTS

output "name_servers" {
  description   = "copy to domain registrar"
  value         = aws_route53_zone.main.name_servers
}