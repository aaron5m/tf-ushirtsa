# DNS ROUTING

resource "aws_route53_record" "website_dns" {
  for_each = toset([
    var.registered_domain_name, 
    "www.${var.registered_domain_name}"
  ])

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# CLOUDFRONT S3

resource "aws_cloudfront_origin_access_control" "website_oac" {
  name                              = "oac-${var.website_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CLOUDFRONT CDN 

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [
    var.registered_domain_name, 
    "www.${var.registered_domain_name}"
  ]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

}

# OUTPUT 

output "cloudfront_distribution_id" {
  description = "Cloudfront Distribution Id"
  value       = aws_cloudfront_distribution.s3_distribution.id
}

# WEBSITE BUCKET

resource "aws_s3_bucket" "website" {
  bucket                    = var.website_bucket_name
  force_destroy             = true

  tags = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

# BUCKET POLICY

resource "aws_s3_bucket_policy" "cloudfront_s3_access" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowCloudFrontServicePrincipalReadOnly"
        Effect   = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

# BUCKET PUBLIC ACCESS BLOCK 

resource "aws_s3_bucket_public_access_block" "website_access" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# HTML TRANSFER UP

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.website.id
  key    = "index.html"
  content_type = "text/html"
  content = templatefile("${path.root}/html/index.html", {
    stripe_public_key   = var.stripe_public_key
    PAYMENT_LAMBDA_URL  = aws_lambda_function_url.lm_payment_url.function_url
  })
  source_hash = sha256(templatefile("${path.root}/html/index.html", {
    stripe_public_key   = var.stripe_public_key
    PAYMENT_LAMBDA_URL  = aws_lambda_function_url.lm_payment_url.function_url
  }))
}

resource "aws_s3_object" "shirt" {
  bucket = aws_s3_bucket.website.id
  key    = "shirt.png"
  source = "html/shirt.png"
  content_type = "image/png"
  etag         = filemd5("html/shirt.png")
}
