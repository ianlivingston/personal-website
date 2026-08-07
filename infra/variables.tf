variable "region" {
  type    = string
  default = "us-east-1"
}

resource "random_uuid" "u" {}

data "aws_iam_policy_document" "public_website" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]
  }
}