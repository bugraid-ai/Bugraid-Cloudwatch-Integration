resource "aws_sns_topic" "sns_topic" {
  name = "BugRaidTopic"
}

resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "https"
  endpoint  = var.webhook_endpoints_url
}
