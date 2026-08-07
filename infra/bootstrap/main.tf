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
}

provider "aws" {
  region = var.region
}

variable "gh_repo" {
  type = string
}

variable "region" {
  type        = string
  description = "Sole region used by AWS resources"
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Project Name"
  default     = "website"
}

variable "oidc_provider_domain" {
  default = "token.actions.githubusercontent.com"
  type    = string
}

variable "oidc_aud" {
  type    = string
  default = "sts.amazonaws.com"
}

resource "random_uuid" "state" {}

#-----------STATE BUCKET---------------
resource "aws_s3_bucket" "state" {
  bucket = substr("webprojects-tfstate-${random_uuid.state.result}", 0, 63)
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#--------GitHub OIDC config--------------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${var.oidc_provider_domain}"
  client_id_list = [var.oidc_aud]
}

resource "aws_iam_role" "trust" {
  name               = "${var.project}-gh-cd"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy" "deploy" {
  name   = "gh-cd"
  policy = data.aws_iam_policy_document.deploy.json
  role   = aws_iam_role.trust.id
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = [aws_iam_openid_connect_provider.github.arn]
      type        = "Federated"
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      values   = [var.oidc_aud]
      variable = "${var.oidc_provider_domain}:aud"
    }
    condition {
      test     = "StringEquals"
      values   = ["repo:${var.gh_repo}:ref:refs/heads/main"]
      variable = "${var.oidc_provider_domain}:sub"
    }
  }
}

data "aws_iam_policy_document" "deploy" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:*",
      "logs:*",
      "s3:*",
      "acm:*",
      "cloudfront:*"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:GetRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:TagRole",
    ]
    resources = ["arn:aws:iam:::role/${var.project}-*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }
}

output "state_bucket" {
  value = aws_s3_bucket.state.id
}

output "deploy_role_arn" {
  value = aws_iam_role.trust.arn
}