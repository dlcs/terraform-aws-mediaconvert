# Queue

Created MediaConvert queue and associated resources. Overall, it will create:

* MediaConvert queue
* IAM role for use by queue
  * Has appropriate access to read/write from `var.input_bucket_name` and `var.output_bucket_name` buckets.
* Cloudwatch EventBridge resource for queue
* New SQS queue with DLQ. 'COMPLETE' and 'ERROR' notifications are sent here.
* New CloudWatch log group. All notifications are sent here.
