resource "aws_sns_topic" "sns_topic" {
  name = "${var.project_name}-topic-${var.environment}"

  tags = {
    Name        = "${var.project_name}-sns-topic"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "https"
  endpoint  = var.webhook_endpoints_url
}
