output "convert_queue_name" {
  description = "Name of MediaConvert queue"
  value       = aws_media_convert_queue.this.name
}

output "convert_queue_arn" {
  description = "Arn of MediaConvert queue"
  value       = aws_media_convert_queue.this.arn
}

output "role_arn" {
  description = "Arn of IAM role for use with queue"
  value       = aws_iam_role.mediaconvert.arn
}

output "transcode_complete_queue_name" {
  description = "Name of SQS queue that receives ERROR and COMPLETE notifications"
  value       = aws_sqs_queue.transcode_completed.name
}

output "transcode_complete_queue_arn" {
  description = "Arn of SQS queue that receives ERROR and COMPLETE notifications"
  value       = aws_sqs_queue.transcode_completed.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of Cloudwatch log group that receives all notifications"
  value       = aws_cloudwatch_log_group.logs.name
}

output "policy_json" {
  description = "Policy that allows use of MediaConvert queue"
  value       = data.aws_iam_policy_document.use_mediaconvert.json
}