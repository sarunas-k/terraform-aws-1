# ---------------------------
# Data
# ---------------------------
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "current" {}

# ---------------------------
# Logs bucket
# ---------------------------
resource "aws_s3_bucket" "access_logs" {
  bucket = var.access_logs_bucket_name

  force_destroy = true

  tags = {
    Name    = var.access_logs_bucket_name
    AppRole = "storage"
  }
}

# ---------------------------
# Policy to prune logs after 30 days
# ---------------------------
resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "expire-access-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# ---------------------------
# Policy document to allow ELB service to write logs
# ---------------------------
data "aws_iam_policy_document" "access_logs" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.access_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.current.arn]
    }
  }
}

# ---------------------------
# Policy of logs S3 bucket
# ---------------------------
resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  policy = data.aws_iam_policy_document.access_logs.json
}
