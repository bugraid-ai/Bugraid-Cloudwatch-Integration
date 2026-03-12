resource "aws_sns_topic" "sns_topic" {
  name = "BugRaidTopic-${var.identifier}"
  tags = merge(var.tags, {
    Name        = "BugRaidTopic-${var.identifier}"
    ManagedBy   = "bugraid"
    Environment = var.identifier
  })
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  arn = aws_sns_topic.sns_topic.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "BugRaidTopicPolicy-${var.identifier}",
    Statement = [
      {
        Sid    = "AllowCloudWatchPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.sns_topic.arn
      },
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_exec_role.arn
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.sns_topic.arn
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "https"
  endpoint  = var.webhook_endpoints_url
}
