variable "identifier" {
  type        = string
  description = "Unique identifier for this deployment (e.g., customer name or tenant ID). Used to avoid resource name collisions."
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.identifier)) && length(var.identifier) >= 2 && length(var.identifier) <= 32
    error_message = "Identifier must be 2-32 characters, alphanumeric and hyphens only."
  }
}

variable "webhook_endpoints_url" {
  type        = string
  description = "The BugRaid webhook HTTPS URL to receive alarm notifications"
  sensitive   = true
  validation {
    condition     = can(regex("^https://", var.webhook_endpoints_url))
    error_message = "Webhook URL must start with https://"
  }
}

variable "daily_event_rule" {
  type        = bool
  description = "Setting this to 'true' will create an EventBridge rule to run the BugRaid Lambda every 2 minutes to subscribe new alarms"
  default     = true
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources in (e.g., us-east-1, eu-west-1)"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources for cost tracking and organization"
  default     = {}
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
