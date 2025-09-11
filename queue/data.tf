data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "input" {
  bucket = var.input_bucket_name
}

data "aws_s3_bucket" "output" {
  bucket = var.output_bucket_name
}
