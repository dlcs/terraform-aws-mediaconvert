locals {
  queue_name = "${var.prefix}-transcode-completed"
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_media_convert_queue" "this" {
  name        = "${var.prefix}-timebased"
  description = var.description

  concurrent_jobs = var.concurrent_jobs
  pricing_plan    = var.pricing_plan
  status          = "ACTIVE"
}

# IAM
resource "aws_iam_role" "mediaconvert" {
  name               = "${var.prefix}-mediaconvert"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["mediaconvert.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "mediaconvert_access" {
  statement {
    sid    = "ReadInputBucket"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject"
    ]

    resources = [
      "${data.aws_s3_bucket.input.arn}/*",
    ]
  }

  statement {
    sid    = "WriteOutputBucket"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      "${data.aws_s3_bucket.output.arn}/*",
    ]
  }

  statement {
    sid    = "ListInputOutput"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      data.aws_s3_bucket.input.arn,
      data.aws_s3_bucket.output.arn,
    ]
  }
}

resource "aws_iam_role_policy" "mediaconvert_s3_access" {
  name   = "${var.prefix}-mediaconvert-s3-access"
  role   = aws_iam_role.mediaconvert.name
  policy = data.aws_iam_policy_document.mediaconvert_access.json
}

# Notifications: MediaConvert -> CloudWatch EventBridge -> SQS
resource "aws_cloudwatch_event_rule" "state_changed" {
  name        = "${var.prefix}-mediaconvert-state"
  description = "MediaConvert completion events for queue ${aws_media_convert_queue.this.name}"

  event_pattern = jsonencode({
    source      = ["aws.mediaconvert"]
    detail-type = ["MediaConvert Job State Change"]
    detail = {
      status = ["COMPLETE", "ERROR"]
      queue  = [aws_media_convert_queue.this.arn]
    }
  })
}

resource "aws_sqs_queue" "transcode_completed" {
  name = local.queue_name

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.transcode_completed_dlq.arn
    maxReceiveCount     = var.max_receives
  })
}

resource "aws_sqs_queue" "transcode_completed_dlq" {
  name = "${local.queue_name}_dlq"
}

resource "aws_sqs_queue_redrive_allow_policy" "transcode_completed" {
  queue_url = aws_sqs_queue.transcode_completed_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.transcode_completed.arn]
  })
}

data "aws_iam_policy_document" "eventbridge_send_sqs" {
  version = "2012-10-17"

  statement {
    sid    = "Eventbridge-to-SQS"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "sqs:SendMessage",
    ]

    resources = [
      aws_sqs_queue.transcode_completed.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_cloudwatch_event_rule.state_changed.arn
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "transcode_completed" {
  queue_url = aws_sqs_queue.transcode_completed.id
  policy    = data.aws_iam_policy_document.eventbridge_send_sqs.json
}

resource "aws_cloudwatch_event_target" "mediaconvert_state_change_sqs" {
  rule      = aws_cloudwatch_event_rule.state_changed.name
  target_id = "${var.prefix}-mediaconvert-state-to-sqs"
  arn       = aws_sqs_queue.transcode_completed.arn
}

# Notifications: MediaConvert -> Cloudwatch Logs
resource "aws_cloudwatch_event_rule" "state_changed_all" {
  name        = "${var.prefix}-mediaconvert-log"
  description = "MediaConvert logging for queue ${aws_media_convert_queue.this.name}"

  event_pattern = jsonencode({
    source      = ["aws.mediaconvert"]
    detail-type = ["MediaConvert Job State Change"]
    detail = {
      queue = [aws_media_convert_queue.this.arn]
    }
  })
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/aws/mediaconvert/logs/${var.prefix}"
  retention_in_days = var.cloudwatch_log_retention
}

data "aws_iam_policy_document" "eventbridge_log" {
  statement {
    sid    = "CreateLogStream"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream"
    ]

    resources = [
      "${aws_cloudwatch_log_group.logs.arn}:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }
  }

  statement {
    sid    = "PutEvents"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.logs.arn}:*:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }

    condition {
      test     = "ArnEquals"
      values   = [aws_cloudwatch_event_rule.state_changed_all.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "mediaconvert" {
  policy_document = data.aws_iam_policy_document.eventbridge_log.json
  policy_name     = "${var.prefix}-mediaconvert-log"
}

resource "aws_cloudwatch_event_target" "logging" {
  rule      = aws_cloudwatch_event_rule.state_changed_all.name
  target_id = "${var.prefix}-mediaconvert-state-to-cloudwatch"
  arn       = aws_cloudwatch_log_group.logs.arn
}

# Policy for using queue
data "aws_iam_policy_document" "use_mediaconvert" {
  statement {
    sid    = "GetQueue"
    effect = "Allow"

    actions = [
      "mediaconvert:GetQueue",
    ]

    resources = [
      aws_media_convert_queue.this.arn,
    ]
  }

  statement {
    sid    = "GetJob"
    effect = "Allow"

    actions = [
      "mediaconvert:GetJob",
    ]

    resources = ["arn:aws:mediaconvert:*:${local.account_id}:jobs/*"]
  }

  statement {
    sid    = "CreateJobAnyPreset"
    effect = "Allow"

    actions = [
      "mediaconvert:CreateJob",
    ]

    resources = [
      aws_media_convert_queue.this.arn,
      "arn:aws:mediaconvert:*:${local.account_id}:presets/*"
    ]
  }

  statement {
    sid    = "PassRole"
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.mediaconvert.arn
    ]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"

      values = [
        "mediaconvert.amazonaws.com",
      ]
    }
  }
}
