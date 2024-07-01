resource "aws_lambda_function" "process_cloudwatch_events" {
  count = var.daily_event_rule ? 1 : 0
  s3_bucket = "bugraid-cloudwatch" #aws_s3_bucket.br_lambda_bucket.bucket
  s3_key = "CloudwatchBugRaidAddTopic.zip" #aws_s3_bucket_object.cloudwatch_lambda_zip.key
  # s3_bucket        = "br-lambdatest"
  # s3_key           = "CloudwatchBugRaidAddTopic.zip"
  function_name    = "BugRaid-CloudWatch-AddTopic"
 # filename = "C:/Users/Admin/Desktop/BigPanda/bugraid-cloudwatch/CloudwatchBugRaidAddTopic.zip"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = filebase64sha256("CloudwatchBugRaidAddTopic.zip")
  environment {
    variables = {
      TOPICARN = aws_sns_topic.sns_topic.arn
    }
  }
}


resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowLambdaInvoke"    #AllowExecutionFromCloudWatch
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_cloudwatch_events[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_event_rule[0].arn
}

