resource "aws_cloudwatch_event_rule" "cloudwatch_event_rule" {
  count       = var.daily_event_rule == true ? 1 : 0
  name        = "cloudwatch_event_rule"
  description = "CloudWatch Event rule to trigger Lambda function"
  schedule_expression = "rate(2 minutes)"
  event_pattern = jsonencode({
    "source": [
      "aws.cloudwatch"
    ],
    "detail-type": [
      "CloudWatch Alarm State Change"
    ]
  })
}


resource "aws_cloudwatch_event_target" "lambda_target" {
  count     = var.daily_event_rule == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.cloudwatch_event_rule[0].name
  target_id = aws_lambda_function.process_cloudwatch_events[0].function_name
  arn       = aws_lambda_function.process_cloudwatch_events[0].arn

}
