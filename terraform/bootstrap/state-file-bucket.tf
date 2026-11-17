resource "aws_s3_bucket" "state_file_bucket" {
  bucket = var.state_file_bucket_name
}

resource "aws_s3_bucket_versioning" "state_file_bucket_versioning" {
  bucket = aws_s3_bucket.state_file_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
