# ---------------------------
# Policy document to manage state files
# ---------------------------
data "aws_iam_policy_document" "bootstrap_role" {

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.state_file_bucket.arn}",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = concat(
      [for key in var.state_file_keys : "${aws_s3_bucket.state_file_bucket.arn}/${key}"],
      [for key in var.state_file_keys : "${aws_s3_bucket.state_file_bucket.arn}/${key}.tflock"],
    )
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject"
    ]
    resources = [for key in var.state_file_keys : "${aws_s3_bucket.state_file_bucket.arn}/${key}.tflock"]
  }

}

# ---------------------------
# Policy to manage state files
# ---------------------------
resource "aws_iam_policy" "bootstrap_role" {
  name   = "bootstrap-role-access"
  policy = data.aws_iam_policy_document.bootstrap_role.json
}

# ---------------------------
# "Bootstrap" role trust policy
# ---------------------------
# Who can assume "bootstrap-role" role: the principals listed in
# var.bootstrap_role_trusted_principal_arns.
data "aws_iam_policy_document" "bootstrap_role_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.bootstrap_role_trusted_principal_arns
    }
  }
}

# ---------------------------
# "Bootstrap" role with trust policy
# ---------------------------
resource "aws_iam_role" "bootstrap_role" {
  name               = "bootstrap-role"
  assume_role_policy = data.aws_iam_policy_document.bootstrap_role_trust_policy.json
}

# ---------------------------
# Policy attachment to "Bootstrap" role
# ---------------------------
resource "aws_iam_role_policy_attachment" "bootstrap_role" {
  role       = aws_iam_role.bootstrap_role.name
  policy_arn = aws_iam_policy.bootstrap_role.arn
}

# ---------------------------
# "Bootstrap" role ARN output
# ---------------------------
output "bootstrap_role_arn" {
  description = "Use as role_arn in the S3 terraform backend"
  value       = aws_iam_role.bootstrap_role.arn
}
