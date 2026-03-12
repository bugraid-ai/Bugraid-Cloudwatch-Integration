output "sns_topic_arn" {
  description = "ARN of the BugRaid SNS topic"
  value       = aws_sns_topic.sns_topic.arn
}

output "lambda_function_name" {
  description = "Name of the BugRaid Lambda function"
  value       = var.daily_event_rule ? aws_lambda_function.process_cloudwatch_events[0].function_name : null
}

output "lambda_function_arn" {
  description = "ARN of the BugRaid Lambda function"
  value       = var.daily_event_rule ? aws_lambda_function.process_cloudwatch_events[0].arn : null
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule that triggers the Lambda"
  value       = var.daily_event_rule ? aws_cloudwatch_event_rule.cloudwatch_event_rule[0].name : null
}

output "deployment_region" {
  description = "AWS region where resources are deployed"
  value       = data.aws_region.current.id
}

output "deployment_account_id" {
  description = "AWS account ID where resources are deployed"
  value       = data.aws_caller_identity.current.account_id
}
