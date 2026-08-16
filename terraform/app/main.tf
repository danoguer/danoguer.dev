provider "aws" {
  region = var.aws_region
}

locals {
  mime_types = {
    "html" = "text/html"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
  }
}

resource "aws_s3_bucket" "mybucket" {
  bucket        = "danoguerportfolio"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "mybucket" {
  bucket = aws_s3_bucket.mybucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "html_files" {
  for_each = fileset("${path.module}/../../src", "*.html")

  bucket       = aws_s3_bucket.mybucket.id
  key          = each.value
  source       = "${path.module}/../../src/${each.value}"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../../src/${each.value}")
}

resource "aws_s3_object" "image_files" {
  for_each = fileset("${path.module}/../../src/images", "**/*.{png,jpg,jpeg}")

  bucket = aws_s3_bucket.mybucket.id
  key    = "images/${each.value}"
  source = "${path.module}/../../src/images/${each.value}"

  content_type = lookup(
    local.mime_types,
    lower(element(split(".", each.value), length(split(".", each.value)) - 1)),
    "application/octet-stream"
  )

  etag = filemd5("${path.module}/../../src/images/${each.value}")
}

data "aws_iam_policy_document" "mys3policy" {
  statement {
    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.mybucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "apply_policy" {
  bucket     = aws_s3_bucket.mybucket.id
  policy     = data.aws_iam_policy_document.mys3policy.json
  depends_on = [aws_s3_bucket_public_access_block.mybucket]
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-s3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"

  aliases = [var.domain_name]

  origin {
    domain_name              = aws_s3_bucket.mybucket.bucket_regional_domain_name
    origin_id                = "S3-miportfolio"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "S3-miportfolio"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = data.aws_cloudfront_cache_policy.optimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [
    aws_s3_bucket.mybucket,
    aws_cloudfront_origin_access_control.oac
  ]
}

resource "terraform_data" "cloudfront_invalidation" {
  triggers_replace = [
    join(",", [for obj in aws_s3_object.html_files : obj.etag]),
    join(",", [for obj in aws_s3_object.image_files : obj.etag])
  ]

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.cdn.id} --paths '/*'"
  }

  depends_on = [
    aws_s3_object.html_files,
    aws_s3_object.image_files,
    aws_cloudfront_distribution.cdn
  ]
}
