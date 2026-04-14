resource "aws_lambda_function" "process_cloudwatch_events" {
  count            = var.daily_event_rule ? 1 : 0
  function_name    = "BugRaid-CloudWatch-AddTopic-${var.identifier}"
  filename         = "${path.module}/CloudwatchBugRaidAddTopic.zip"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  timeout          = 120
  memory_size      = 128
  source_code_hash = filebase64sha256("${path.module}/CloudwatchBugRaidAddTopic.zip")

  environment {
    variables = {
      TOPICARN = aws_sns_topic.sns_topic.arn
    }
  }

  tags = merge(var.tags, {
    Name        = "BugRaid-CloudWatch-AddTopic-${var.identifier}"
    ManagedBy   = "bugraid"
    Environment = var.identifier
  })
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = var.daily_event_rule == true ? 1 : 0
  statement_id  = "AllowLambdaInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_cloudwatch_events[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_event_rule[0].arn
}
