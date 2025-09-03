# BugRaid CloudWatch Integration

This Terraform configuration creates AWS resources for BugRaid CloudWatch integration with improved error handling, proper naming conventions, and enhanced security.

## 🚀 Quick Start

1. **Configure AWS Credentials**
   ```bash
   aws configure
   # OR set environment variables:
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="ap-southeast-1"
   ```

2. **Create terraform.tfvars file**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Deploy Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## 📋 Resources Created

- **SNS Topic**: For CloudWatch alarm notifications
- **Lambda Function**: Processes CloudWatch events and manages alarm subscriptions
- **CloudWatch Event Rule**: Triggers Lambda function on alarm state changes
- **IAM Roles & Policies**: Least-privilege access for Lambda execution
- **CloudFormation Stack**: Custom resource for alarm subscription management

## ⚙️ Configuration Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `subscribe_all` | bool | - | Automatically subscribe all CloudWatch alarms to BugRaid topic |
| `daily_event_rule` | bool | - | Create daily event rule for Lambda execution |
| `webhook_endpoints_url` | string | - | Webhook URL for SNS subscription |
| `environment` | string | "dev" | Environment name (dev, staging, prod) |
| `project_name` | string | "bugraid" | Project name for resource naming |
| `lambda_timeout` | number | 300 | Lambda function timeout in seconds |
| `aws_region` | string | "us-east-1" | AWS region for deployment |

## 🔧 Recent Improvements

### Fixed Issues:
- ✅ Added AWS provider version constraints
- ✅ Fixed CloudFormation stack conditional logic
- ✅ Replaced hardcoded names with dynamic naming
- ✅ Implemented least-privilege IAM policies
- ✅ Added comprehensive error handling
- ✅ Added resource tags for better management
- ✅ Fixed Lambda timeout configuration
- ✅ Improved CloudFormation template structure

### Security Enhancements:
- 🔒 Removed overly broad SNS permissions
- 🔒 Scoped IAM policies to specific resources
- 🔒 Added proper resource-based permissions
- 🔒 Implemented least-privilege access patterns

## 🐛 Troubleshooting

### Common Issues:

1. **Timeout Errors**
   - Increase `lambda_timeout` variable (default: 300 seconds)
   - Check Lambda function logs in CloudWatch
   - Verify webhook endpoint is accessible

2. **Permission Errors**
   - Ensure AWS credentials have sufficient permissions
   - Check IAM policies for CloudWatch and SNS access
   - Verify Lambda execution role permissions

3. **Resource Naming Conflicts**
   - Use different `project_name` or `environment` values
   - Check for existing resources with same names

### Debug Commands:
```bash
# Validate configuration
terraform validate

# Check plan without applying
terraform plan

# View current state
terraform show

# Check Lambda logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/bugraid"
```

## 📊 Monitoring

After deployment, monitor:
- Lambda function execution metrics
- CloudWatch alarm state changes
- SNS topic delivery success rates
- Error rates in CloudWatch logs

## 🧹 Cleanup

To destroy all resources:
```bash
terraform destroy
```

## 📝 Notes

- The Lambda function processes CloudWatch alarm state changes
- SNS topic receives notifications and forwards to webhook
- CloudFormation stack manages custom resource lifecycle
- All resources are tagged for cost tracking and management

