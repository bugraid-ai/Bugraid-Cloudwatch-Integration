resource "aws_lambda_function" "process_cloudwatch_events" {
  count = var.daily_event_rule ? 1 : 0
  function_name    = "${var.project_name}-cloudwatch-addtopic-${var.environment}"
  filename         = "${path.module}/CloudwatchBugRaidAddTopic.zip"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = var.lambda_timeout
  memory_size      = 256
  source_code_hash = filebase64sha256("${path.module}/CloudwatchBugRaidAddTopic.zip")
  
  environment {
    variables = {
      TOPICARN = aws_sns_topic.sns_topic.arn
    }
  }

  tags = {
    Name        = "${var.project_name}-cloudwatch-lambda"
    Environment = var.environment
    Project     = var.project_name
  }
}


resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowLambdaInvoke"    #AllowExecutionFromCloudWatch
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_cloudwatch_events[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_event_rule[0].arn
}

