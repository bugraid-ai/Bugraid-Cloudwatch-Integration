variable "subscribe_all" {
  type        = bool
  description = "Setting this to 'true' will automatically add the BugRaid Topic to all existing CloudWatch Alarms"
}


variable "webhook_endpoints_url" {
    type = string
    description = "enter the webhook url to test"
}


variable "daily_event_rule" {
  type        = bool
  description = "Setting this to 'true' will create a CloudWatch Event to run the BugRaid SubscribeAll Lambda once a day"
}

data "aws_region" "current" {}
