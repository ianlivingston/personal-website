terraform {
  required_version = "~> 1.15.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket       = "webprojects-tfstate-62afcd61-b2c1-6a59-dce1-d7b7c605f88e"
    key          = "personal-website/infra"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "personal-website"
      ManagedBy = "terraform"
    }
  }
}

resource "aws_s3_bucket" "website" {
  bucket = substr("webprojects-website-${random_uuid.u.result}", 0, 63)

}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.public_website.json
}

resource "aws_acm_certificate" "home" {
  domain_name       = local.apex_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    origin_id                = local.home_origin
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = local.root_object
  aliases             = [local.apex_domain]

  default_cache_behavior {
    allowed_methods        = ["HEAD", "DELETE", "GET", "POST", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.home_origin
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimized_uncompressed.id
    viewer_protocol_policy = "redirect-to-https"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa-url.arn
    }
  }

  ordered_cache_behavior {
    path_pattern     = "*.svg"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.home_origin
    cache_policy_id  = data.aws_cloudfront_cache_policy.optimized.id

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.home.arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "default-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "spa-url" {
  code    = file("${path.module}/spa-url.js")
  name    = "spa-url"
  runtime = "cloudfront-js-2.0"
  publish = true
}