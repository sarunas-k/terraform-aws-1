locals {
  infra_control_name            = "infra-control"
  infra_control_allowed_origins = ["https://${var.dns_record_name}"]
}

# ---------------------------
# Container registry for infra-control Lambda image
# ---------------------------
module "infra_control_ecr" {
  source = "./modules/elastic-container-registry"

  name                   = local.infra_control_name
  read_write_access_arns = var.ecr_read_write_access_arns

  lambda_read_access_arns = [
    "arn:aws:lambda:${var.aws_region}:${local.account_id}:function:${local.infra_control_name}",
  ]
}

# ---------------------------
# Image tag
# ---------------------------
data "aws_ssm_parameter" "infra_control_image_tag" {
  name = "/${local.infra_control_name}/image-tag"
}

# ---------------------------
# Secret with GitHub token and passcode
# ---------------------------
resource "aws_secretsmanager_secret" "infra_control" {
  name        = local.infra_control_name
  description = "GitHub token and button passcode for infra-control"

  recovery_window_in_days = 0
}

# ---------------------------
# Lambda role trust policy
# ---------------------------
data "aws_iam_policy_document" "infra_control_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ---------------------------
# Lambda role policy. Write logs, read secret
# ---------------------------
data "aws_iam_policy_document" "infra_control" {
  statement {
    sid       = "WriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.infra_control.arn}:*"]
  }

  statement {
    sid       = "ReadSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.infra_control.arn]
  }
}

# ---------------------------
# Lambda role
# ---------------------------
resource "aws_iam_role" "infra_control" {
  name               = "${local.infra_control_name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.infra_control_trust.json
}

resource "aws_iam_role_policy" "infra_control" {
  name   = "${local.infra_control_name}-lambda"
  role   = aws_iam_role.infra_control.id
  policy = data.aws_iam_policy_document.infra_control.json
}

# ---------------------------
# Lambda log group
# ---------------------------
resource "aws_cloudwatch_log_group" "infra_control" {
  name              = "/aws/lambda/${local.infra_control_name}"
  retention_in_days = 14
}

# ---------------------------
# Lambda function. Starts apply and destroy GitHub workflows
# ---------------------------
resource "aws_lambda_function" "infra_control" {
  function_name = local.infra_control_name
  description   = "Starts the apply and destroy GitHub workflows for the primary environment"
  role          = aws_iam_role.infra_control.arn

  package_type  = "Image"
  image_uri     = "${module.infra_control_ecr.repository_url}:${data.aws_ssm_parameter.infra_control_image_tag.insecure_value}"
  architectures = ["x86_64"]

  memory_size = 256
  timeout     = 30

  reserved_concurrent_executions = 1

  environment {
    variables = {
      SECRET_ID        = aws_secretsmanager_secret.infra_control.name
      GITHUB_REPO      = var.github_repo
      APPLY_WORKFLOW   = "apply.yml"
      DESTROY_WORKFLOW = "destroy.yml"
      COOLDOWN_SECONDS = tostring(var.infra_control_cooldown_seconds)
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.infra_control.name
  }

  depends_on = [
    aws_iam_role_policy.infra_control,
    module.infra_control_ecr,
  ]
}

# ---------------------------
# Public function URL for buttons
# ---------------------------
resource "aws_lambda_function_url" "infra_control" {
  function_name      = aws_lambda_function.infra_control.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = local.infra_control_allowed_origins
    allow_methods = ["POST"]
    allow_headers = ["content-type"]
    max_age       = 3600
  }
}

# ---------------------------
# Scheduler role trust policy
# ---------------------------
data "aws_iam_policy_document" "infra_control_scheduler_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

# ---------------------------
# Scheduler role policy
# ---------------------------
data "aws_iam_policy_document" "infra_control_scheduler" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.infra_control.arn]
  }
}

# ---------------------------
# Scheduler role
# ---------------------------
resource "aws_iam_role" "infra_control_scheduler" {
  name               = "${local.infra_control_name}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.infra_control_scheduler_trust.json
}

resource "aws_iam_role_policy" "infra_control_scheduler" {
  name   = "${local.infra_control_name}-scheduler"
  role   = aws_iam_role.infra_control_scheduler.id
  policy = data.aws_iam_policy_document.infra_control_scheduler.json
}

# ---------------------------
# Daily shutdown of primary environment
# ---------------------------
resource "aws_scheduler_schedule" "infra_control_daily_destroy" {
  name        = "${local.infra_control_name}-daily-destroy"
  description = "Shuts down the primary environment every day"

  schedule_expression          = var.infra_control_destroy_schedule
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.infra_control.arn
    role_arn = aws_iam_role.infra_control_scheduler.arn
    input    = jsonencode({ source = "scheduler", action = "destroy" })

    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 3
    }
  }
}

# ---------------------------
# Outputs
# ---------------------------
output "infra_control_url" {
  description = "Function URL behind the buttons"
  value       = aws_lambda_function_url.infra_control.function_url
}
