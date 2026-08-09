variable "region" {
  type    = string
  default = "us-east-1"
}

resource "random_uuid" "u" {}

data "aws_iam_policy_document" "public_website" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]
  }
}

locals {
  root_object = "index.html"
  home_origin = "home-page"
  apex_domain = "ianlivingston.dev"
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "optimized_uncompressed" {
  name = "Managed-CachingOptimizedForUncompressedObjects"
}