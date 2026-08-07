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

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  index_document {
    suffix = aws_s3_object.home_html.key
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.public_website.json
}

resource "aws_s3_object" "home_html" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "../home-page/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "home_css" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.css"
  source       = "../home-page/index.css"
  content_type = "text/css"
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}