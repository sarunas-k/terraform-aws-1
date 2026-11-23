# ---------------------------
# "EC2 app" role trust policy
# ---------------------------
# Who can assume "ec2-app" role
data "aws_iam_policy_document" "ec2_app_role_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ---------------------------
# "EC2 app" role with trust policy
# ---------------------------
resource "aws_iam_role" "ec2_app" {
  name               = var.ec2_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_app_role_trust_policy.json
}

# ---------------------------
# "EC2 app" policy document
# ---------------------------
data "aws_iam_policy_document" "ec2_app_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [data.aws_ssm_parameter.image_tag.arn]
  }
}

# ---------------------------
# "EC2 app" policy
# ---------------------------
resource "aws_iam_policy" "ec2_app" {
  name   = "${var.ec2_role_name}-policy"
  policy = data.aws_iam_policy_document.ec2_app_policy.json
}

# ---------------------------
# Policy attachments to "EC2 app" role
# ---------------------------
resource "aws_iam_role_policy_attachment" "ec2_app_ecr_read_only" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_app" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = aws_iam_policy.ec2_app.arn
}

# ---------------------------
# Instance profile for "EC2 app" role
# ---------------------------
resource "aws_iam_instance_profile" "ec2_app" {
  name = aws_iam_role.ec2_app.name
  role = aws_iam_role.ec2_app.name
}
