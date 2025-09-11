variable "prefix" {
  description = "Prefix for AWS resources"
  type        = string
}

variable "concurrent_jobs" {
  description = "The maximum number of jobs your queue can process concurrently"
  default     = 200
}

variable "description" {
  description = "Description of the queue"
  default     = "Protagonist trancodes"
}

variable "pricing_plan" {
  description = "Pricing plan for queue"
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "RESERVED"], var.pricing_plan)
    error_message = "pricing_plan must be 'ON_DEMAND' or 'RESERVED'"
  }
}

variable "input_bucket_name" {
  description = "S3 bucket where AV inputs are placed"
  type        = string
}

variable "output_bucket_name" {
  description = "S3 bucket where AV outputs are placed"
  type        = string
}

variable "cloudwatch_log_retention" {
  default = 7
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue"
  default     = 30
}

variable "message_retention_seconds" {
  description = "The number of seconds that SQS retains a message"
  default     = 1209600
}

variable "message_retention_seconds_dlq" {
  description = "The number of seconds that SQS DLQ retains a message"
  default     = 1209600
}

variable "max_message_size" {
  description = "Maximum message size allowed by SQS, in bytes"
  default     = 262144
}

variable "delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the queue will be delayed"
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning"
  default     = 0
}

variable "max_receives" {
  description = "The number of retries before moving SQS message to DLQ"
  default     = 3
}
