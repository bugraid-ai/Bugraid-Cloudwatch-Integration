resource "aws_cloudwatch_event_rule" "cloudwatch_event_rule" {
  count               = var.daily_event_rule == true ? 1 : 0
  name                = "bugraid-cloudwatch-event-rule-${var.identifier}"
  description         = "Triggers BugRaid Lambda to subscribe new CloudWatch alarms"
  schedule_expression = "rate(2 minutes)"

  tags = merge(var.tags, {
    Name        = "bugraid-cloudwatch-event-rule-${var.identifier}"
    ManagedBy   = "bugraid"
    Environment = var.identifier
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  count     = var.daily_event_rule == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.cloudwatch_event_rule[0].name
  target_id = aws_lambda_function.process_cloudwatch_events[0].function_name
  arn       = aws_lambda_function.process_cloudwatch_events[0].arn
}
