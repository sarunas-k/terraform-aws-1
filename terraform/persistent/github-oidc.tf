# ---------------------------
# Open ID Connect provider - GitHub
# ---------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# ---------------------------
# Trust policy - apply role. Only main branch workflows
# ---------------------------
data "aws_iam_policy_document" "github_actions_apply_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

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
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

# ---------------------------
# Trust policy - plan role. Only pull request workflows
# ---------------------------
data "aws_iam_policy_document" "github_actions_plan_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

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
      values   = ["repo:${var.github_repo}:pull_request"]
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ---------------------------
# Permissions policy - apply role
# ---------------------------
data "aws_iam_policy_document" "github_actions_apply_policy" {
  # ---------------------------
  # Terraform state
  # ---------------------------
  statement {
    sid       = "AssumeStateRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/bootstrap-role"]
  }

  # ---------------------------
  # VPC, endpoints, security groups, launch template, ALB, ASG
  # ---------------------------
  statement {
    sid    = "Compute"
    effect = "Allow"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
  
  # ---------------------------
  # IAM Read Only
  # ---------------------------
  statement {
    sid       = "IamReadOnly"
    effect    = "Allow"
    actions   = ["iam:Get*", "iam:List*"]
    resources = ["*"]
  }

  # ---------------------------
  # EC2 custom app role
  # ---------------------------
  statement {
    sid    = "IamAppRoles"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/ec2-*"]
  }

  statement {
    sid    = "IamAppRolePolicyAttachment"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/ec2-*"]

    condition {
      test     = "ArnLike"
      variable = "iam:PolicyARN"
      values = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::${local.account_id}:policy/ec2-*",
      ]
    }
  }

  statement {
    sid    = "IamAppPolicies"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = ["arn:aws:iam::${local.account_id}:policy/ec2-*"]
  }

  statement {
    sid    = "IamAppInstanceProfiles"
    effect = "Allow"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
    ]
    resources = ["arn:aws:iam::${local.account_id}:instance-profile/ec2-*"]
  }

  statement {
    sid       = "IamPassAppRoleToEc2"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/ec2-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  # ---------------------------
  # Certificate Manager
  # ---------------------------
  statement {
    sid       = "ACM"
    effect    = "Allow"
    actions   = ["acm:*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = distinct([var.aws_region, "us-east-1"])
    }
  }
  
  # ---------------------------
  # Route53 and CloudFront
  # ---------------------------
  statement {
    sid    = "DnsAndCdn"
    effect = "Allow"
    actions = [
      "route53:*",
      "cloudfront:*",
    ]
    resources = ["*"]
  }
  
  # ---------------------------
  # Container Registry
  # ---------------------------
  statement {
    sid       = "ECR"
    effect    = "Allow"
    actions   = ["ecr:*"]
    resources = ["arn:aws:ecr:${var.aws_region}:${local.account_id}:repository/*"]
  }
  
  # ---------------------------
  # S3
  # ---------------------------
  statement {
    sid     = "S3Buckets"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.failover_site_bucket}",
      "arn:aws:s3:::${var.failover_site_bucket}/*",
      "arn:aws:s3:::alb-logs-${local.account_id}-*",
      "arn:aws:s3:::alb-logs-${local.account_id}-*/*",
    ]
  }

  # ---------------------------
  # Systems Manager
  # ---------------------------
  statement {
    sid       = "SSMParameter"
    effect    = "Allow"
    actions   = ["ssm:*"]
    resources = ["arn:aws:ssm:${var.aws_region}:${local.account_id}:parameter/app/*"]
  }

  statement {
    sid       = "SSMDescribe"
    effect    = "Allow"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }
}

# ---------------------------
# IAM Role for apply workflow
# ---------------------------
resource "aws_iam_role" "github_actions_apply" {
  name               = "${var.environment}-github-actions-apply"
  assume_role_policy = data.aws_iam_policy_document.github_actions_apply_trust_policy.json
}

resource "aws_iam_role_policy" "github_actions_apply" {
  name   = "${var.environment}-github-actions-apply"
  role   = aws_iam_role.github_actions_apply.id
  policy = data.aws_iam_policy_document.github_actions_apply_policy.json
}

# ---------------------------
# IAM Role for plan workflow
# ---------------------------
data "aws_iam_policy_document" "github_actions_plan_policy" {
  statement {
    sid       = "AssumeStateRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/bootstrap-role"]
  }
}

resource "aws_iam_role" "github_actions_plan" {
  name               = "${var.environment}-github-actions-plan"
  assume_role_policy = data.aws_iam_policy_document.github_actions_plan_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "github_actions_plan_read_only" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "github_actions_plan" {
  name   = "${var.environment}-github-actions-plan"
  role   = aws_iam_role.github_actions_plan.id
  policy = data.aws_iam_policy_document.github_actions_plan_policy.json
}

output "github_actions_plan_role_arn" {
  description = "Set as GitHub repo secret AWS_TF_PLAN_ROLE_ARN"
  value       = aws_iam_role.github_actions_plan.arn
}

output "github_actions_apply_role_arn" {
  description = "Set as GitHub repo secret AWS_TF_APPLY_ROLE_ARN"
  value       = aws_iam_role.github_actions_apply.arn
}
