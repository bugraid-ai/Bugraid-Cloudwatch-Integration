variable "subscribe_all" {
  type        = bool
  description = "Setting this to 'true' will automatically add the BugRaid Topic to all existing CloudWatch Alarms"
  default     = true
}


variable "webhook_endpoints_url" {
    type = string
    description = "enter the webhook url to test"
    default     = "https://dev-api.bugraid.ai/alerts/6a1538fc-2d57-4fa2-b381-21585ce176b2?auth_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb21wYW55X2lkIjoiY21kbmFxNHNjMDAwMDJxMDFjamRuZHg4aSIsImNvbXBhbnlfbmFtZSI6ImJ1Z3JhaWQiLCJlbWFpbCI6InNuZWgudGhha2thckBjb2duaXRpdmVjb3JlYWkuY29tIiwiaWQiOiIwOTBhMTU4Yy04MDcxLTcwYTctMWU3Mi0zY2QyYzBlMzRjNzEiLCJjb21wc2x1ZyI6ImJ1Z3JhaWQiLCJidWNrZXRfbmFtZSI6ImRldi1idWdyYWlkLWJ1Z3JhaWQtNTc0Nzc4MjMxNjYwIiwicm9sZSI6IkFETUlOIiwiaWF0IjoxNzU2NzkyNTIwfQ.jq3D8sivJ6ecsbLotQ376QwpJ13FFKgYbLXQ5fvCQKc"
}


variable "daily_event_rule" {
  type        = bool
  description = "Setting this to 'true' will create a CloudWatch Event to run the BugRaid SubscribeAll Lambda once a day"
  default     = true
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "bugraid"
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda function timeout in seconds"
  default     = 300
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
