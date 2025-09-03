resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-lambda-exec-role-${var.environment}"
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

  tags = {
    Name        = "${var.project_name}-lambda-exec-role"
    Environment = var.environment
    Project     = var.project_name
  }
}


resource "aws_iam_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*"
      },
      {
        Action = [
          "sns:ConfirmSubscription",
          "sns:Publish"
        ],
        Effect = "Allow",
        Resource = aws_sns_topic.sns_topic.arn
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-lambda-policy"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


data "aws_iam_policy_document" "bugraid_cloudwatch_lambda" {
  statement {
    sid    = "AllowBugraidLambdaToListAlarms"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "bugraid_cloudwatch_lambda" {
  name   = "${var.project_name}-cloudwatch-lambda-${var.environment}"
  policy = data.aws_iam_policy_document.bugraid_cloudwatch_lambda.json

  tags = {
    Name        = "${var.project_name}-cloudwatch-lambda-policy"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "BugraidCloudWatchLambda_policy" {
  count      = var.daily_event_rule ? 1 : 0
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.bugraid_cloudwatch_lambda.arn
}
