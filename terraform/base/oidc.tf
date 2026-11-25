resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:danoguer/danoguer.dev:ref:refs/heads/main"]
    }
  }
}

data "aws_iam_policy_document" "github_actions_plan" {
  statement {
    sid       = "ReadCallerIdentity"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid     = "ListTerraformBuckets"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::danoguer-dev-tfstate-portfolio-bucket",
      "arn:aws:s3:::danoguerportfolio"
    ]
  }

  statement {
    sid     = "ReadTerraformStateAndApplicationBucket"
    actions = ["s3:Get*"]
    resources = [
      "arn:aws:s3:::danoguer-dev-tfstate-portfolio-bucket",
      "arn:aws:s3:::danoguer-dev-tfstate-portfolio-bucket/app/terraform.tfstate",
      "arn:aws:s3:::danoguerportfolio",
      "arn:aws:s3:::danoguerportfolio/*"
    ]
  }

  statement {
    sid       = "LockTerraformState"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::danoguer-dev-tfstate-portfolio-bucket/app/terraform.tfstate.tflock"]
  }

  statement {
    sid = "ListCloudFrontResources"
    actions = [
      "cloudfront:ListCachePolicies",
      "cloudfront:ListDistributions",
      "cloudfront:ListOriginAccessControls"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ReadCloudFrontResources"
    actions = [
      "cloudfront:GetCachePolicy",
      "cloudfront:GetCachePolicyConfig",
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:GetOriginAccessControlConfig",
      "cloudfront:ListTagsForResource"
    ]
    resources = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    sid       = "ListCertificates"
    actions   = ["acm:ListCertificates"]
    resources = ["*"]
  }

  statement {
    sid       = "ReadPortfolioCertificate"
    actions   = ["acm:DescribeCertificate", "acm:ListTagsForCertificate"]
    resources = ["arn:aws:acm:us-east-1:${data.aws_caller_identity.current.account_id}:certificate/*"]
  }

  statement {
    sid = "ReadRoute53ZonesAndRecords"
    actions = [
      "route53:GetHostedZone",
      "route53:ListTagsForResource",
      "route53:ListResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    sid = "ListRoute53Zones"
    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ReadLambdaFunction"
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:GetFunctionUrlConfig",
      "lambda:GetPolicy",
      "lambda:ListTags"
    ]
    resources = ["arn:aws:lambda:eu-west-1:${data.aws_caller_identity.current.account_id}:function:aws-portfolio-contact-backend"]
  }

  statement {
    sid = "ReadLambdaExecutionRole"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListRoleTags"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-portfolio-contact-lambda-role"]
  }

  statement {
    sid = "ReadLambdaPolicy"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/aws-portfolio-contact-lambda-policy"]
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-danoguer-dev-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

resource "aws_iam_role_policy" "github_actions_plan" {
  name   = "terraform-plan-only"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_plan.json
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN del rol OIDC para GitHub Actions"
}
