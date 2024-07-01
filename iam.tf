resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
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
}


resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "sns:ConfirmSubscription"
        ],
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = "sns:Publish",
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count       = var.daily_event_rule ? 1 : 0
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "sns_publish_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}


data "aws_iam_policy_document" "bugraid_cloudwatch_lambda" {
  statement {
    sid    = "AllowBugraidLambdaToListAlarms"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DescribeAlarms"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "bugraid_cloudwatch_lambda" {
  name   = "BugraidCloudWatchLambda"
  policy = data.aws_iam_policy_document.bugraid_cloudwatch_lambda.json
}

resource "aws_iam_role_policy_attachment" "BugraidCloudWatchLambda_policy" {
  count      = var.daily_event_rule ? 1 : 0
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.bugraid_cloudwatch_lambda.arn
}
