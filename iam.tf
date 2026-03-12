resource "aws_iam_role" "lambda_exec_role" {
  name = "bugraid-cw-lambda-role-${var.identifier}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "bugraid-cw-lambda-role-${var.identifier}"
    ManagedBy   = "bugraid"
    Environment = var.identifier
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "bugraid-cw-lambda-policy-${var.identifier}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowLogging"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/BugRaid-CloudWatch-AddTopic-${var.identifier}:*"
      },
      {
        Sid = "AllowSNSPublish"
        Action = [
          "sns:Publish",
          "sns:ConfirmSubscription"
        ],
        Effect   = "Allow",
        Resource = aws_sns_topic.sns_topic.arn
      },
      {
        Sid = "AllowDescribeAlarms"
        Action = [
          "cloudwatch:DescribeAlarms"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Sid = "AllowPutMetricAlarm"
        Action = [
          "cloudwatch:PutMetricAlarm"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:cloudwatch:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:alarm:*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "bugraid-cw-lambda-policy-${var.identifier}"
    ManagedBy   = "bugraid"
    Environment = var.identifier
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
