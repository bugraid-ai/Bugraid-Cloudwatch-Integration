# Bugraid-Cloudwatch-Integration

This codebase sets up the AWS infrastructure using Terraform to integrate CloudWatch with bugraid.ai. It allows CloudWatch alarms to be sent to a bugraidCloudwatch (inbound) integration within the customer organization.

Prerequisites:
1. Terraform is installed. (Install Terraform using https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli )
2. AWS CLI is installed. (Install AWS CLI using https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html )
3. AWS is configured. (Run: aws configure)

Setup Instructions:
1. Clone the repository.
2. Navigate to the cloned repository's folder.

RUN:
1. terraform init
2. terraform plan
3. terraform apply

In case, you need to delete the infrastructure created with terraform, run
terraform destroy

Note:
1. This terraform script uses 3 input variables: webhook url(provided in the integration guide in bugraid.ai application), subscribe_all, daily_event_rule. 
2. subscribe_all and daily_event_rule accept boolean values and need to be set to “true” to create appropriate terraform resources.

