# Outputs for BugRaid CloudWatch Integration

# SNS Topic Information
output "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarm notifications"
  value       = aws_sns_topic.sns_topic.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.sns_topic.name
}

# Lambda Function Information
output "lambda_function_arn" {
  description = "ARN of the Lambda function that processes CloudWatch events"
  value       = var.daily_event_rule ? aws_lambda_function.process_cloudwatch_events[0].arn : null
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = var.daily_event_rule ? aws_lambda_function.process_cloudwatch_events[0].function_name : null
}

output "lambda_function_timeout" {
  description = "Timeout setting for the Lambda function"
  value       = var.daily_event_rule ? aws_lambda_function.process_cloudwatch_events[0].timeout : null
}

# CloudWatch Event Rule Information
output "cloudwatch_event_rule_arn" {
  description = "ARN of the CloudWatch Event rule"
  value       = var.daily_event_rule ? aws_cloudwatch_event_rule.cloudwatch_event_rule[0].arn : null
}

output "cloudwatch_event_rule_name" {
  description = "Name of the CloudWatch Event rule"
  value       = var.daily_event_rule ? aws_cloudwatch_event_rule.cloudwatch_event_rule[0].name : null
}

output "cloudwatch_event_schedule" {
  description = "Schedule expression for the CloudWatch Event rule"
  value       = var.daily_event_rule ? aws_cloudwatch_event_rule.cloudwatch_event_rule[0].schedule_expression : null
}

# IAM Role Information
output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_exec_role.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_exec_role.name
}

# CloudFormation Stack Information
output "cloudformation_stack_id" {
  description = "ID of the CloudFormation stack"
  value       = var.subscribe_all ? aws_cloudformation_stack.trigger_codebuild_stack[0].id : null
}

output "cloudformation_stack_name" {
  description = "Name of the CloudFormation stack"
  value       = var.subscribe_all ? aws_cloudformation_stack.trigger_codebuild_stack[0].name : null
}

output "cloudformation_stack_status" {
  description = "Status of the CloudFormation stack"
  value       = var.subscribe_all ? aws_cloudformation_stack.trigger_codebuild_stack[0].outputs : null
}

# SNS Subscription Information
output "sns_subscription_arn" {
  description = "ARN of the SNS subscription"
  value       = aws_sns_topic_subscription.sns_subscription.arn
}

output "sns_subscription_endpoint" {
  description = "Endpoint URL for the SNS subscription"
  value       = aws_sns_topic_subscription.sns_subscription.endpoint
  sensitive   = true  # Mark as sensitive since it contains auth token
}

# Environment and Configuration Information
output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID where resources are deployed"
  value       = data.aws_caller_identity.current.account_id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# Resource Summary
output "resource_summary" {
  description = "Summary of all created resources"
  value = {
    sns_topic_arn           = aws_sns_topic.sns_topic.arn
    lambda_function_arn     = var.daily_event_rule ? aws_lambda_function.process_cloudwatch_events[0].arn : null
    cloudwatch_event_rule   = var.daily_event_rule ? aws_cloudwatch_event_rule.cloudwatch_event_rule[0].name : null
    cloudformation_stack    = var.subscribe_all ? aws_cloudformation_stack.trigger_codebuild_stack[0].name : null
    lambda_execution_role   = aws_iam_role.lambda_exec_role.name
    region                  = data.aws_region.current.name
    account_id              = data.aws_caller_identity.current.account_id
  }
}
