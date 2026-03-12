# BugRaid CloudWatch Integration

Automatically connect all your AWS CloudWatch alarms to [BugRaid AI](https://bugraid.ai) — your AI SRE agent. Once deployed, every new CloudWatch alarm in your account is automatically discovered and routed to BugRaid for intelligent incident detection and response.

## How It Works

```
Your AWS Account
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  EventBridge Rule (every 5 min)                         │
│       │                                                 │
│       ▼                                                 │
│  Lambda Function                                        │
│       │  Discovers all CloudWatch alarms                │
│       │  Adds BugRaid SNS topic to new alarms           │
│       │  Skips already-subscribed alarms                 │
│       ▼                                                 │
│  CloudWatch Alarm fires ──▶ SNS Topic ──▶ BugRaid AI   │
│                                (HTTPS)                  │
└─────────────────────────────────────────────────────────┘
```

**What gets deployed:**

| Resource | Purpose |
|----------|---------|
| SNS Topic | Receives alarm notifications and forwards to BugRaid |
| Lambda Function | Discovers new alarms and subscribes them to the SNS topic |
| EventBridge Rule | Triggers the Lambda every 5 minutes |
| IAM Role & Policy | Least-privilege permissions for the Lambda |

## Prerequisites

1. **Terraform** (v1.2+) — [Install guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
2. **AWS CLI** — [Install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. **AWS credentials configured** with permissions to create Lambda, SNS, EventBridge, and IAM resources

### Required AWS Permissions

The user/role running Terraform needs these permissions:

```
lambda:CreateFunction, lambda:DeleteFunction, lambda:GetFunction,
lambda:UpdateFunctionCode, lambda:UpdateFunctionConfiguration,
lambda:AddPermission, lambda:RemovePermission

sns:CreateTopic, sns:DeleteTopic, sns:Subscribe, sns:Unsubscribe,
sns:SetTopicAttributes, sns:GetTopicAttributes

events:PutRule, events:DeleteRule, events:PutTargets, events:RemoveTargets

iam:CreateRole, iam:DeleteRole, iam:AttachRolePolicy, iam:DetachRolePolicy,
iam:CreatePolicy, iam:DeletePolicy, iam:GetRole, iam:PassRole

logs:CreateLogGroup, logs:DeleteLogGroup
```

## Quick Start (5 minutes)

### Step 1: Clone the repository

```bash
git clone <repository-url>
cd Bugraid-Cloudwatch-Integration
```

### Step 2: Configure your deployment

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
identifier            = "your-company-name"
webhook_endpoints_url = "https://app.bugraid.ai/webhook/your-webhook-key"
```

> Your `webhook_endpoints_url` is available in your BugRaid dashboard under **Settings > Integrations > CloudWatch**.

### Step 3: Deploy

```bash
terraform init
terraform plan
terraform apply
```

That's it. Within 5 minutes, all your existing CloudWatch alarms will be connected to BugRaid. Any new alarms you create will be automatically discovered and connected.

### Step 4: Verify

After deployment, Terraform will output:

```
sns_topic_arn        = "arn:aws:sns:us-east-1:123456789012:BugRaidTopic-your-company-name"
lambda_function_name = "BugRaid-CloudWatch-AddTopic-your-company-name"
deployment_region    = "us-east-1"
deployment_account_id = "123456789012"
```

You can verify the Lambda is running:

```bash
# Check recent Lambda invocations
aws logs tail /aws/lambda/BugRaid-CloudWatch-AddTopic-your-company-name --since 5m
```

## Configuration Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `identifier` | Yes | — | Unique name for your deployment (e.g., company name). 2-32 chars, alphanumeric and hyphens. |
| `webhook_endpoints_url` | Yes | — | Your BugRaid webhook URL (provided in your BugRaid dashboard). Must be HTTPS. |
| `daily_event_rule` | No | `true` | Enables automatic alarm discovery every 5 minutes. |
| `aws_region` | No | AWS CLI default | AWS region to deploy in (e.g., `us-east-1`). |
| `tags` | No | `{}` | Custom tags applied to all resources for cost tracking. |

### Example: Full configuration

```hcl
identifier            = "acme-corp"
webhook_endpoints_url = "https://app.bugraid.ai/webhook/abc123"
aws_region            = "us-west-2"
daily_event_rule      = true

tags = {
  Team        = "platform"
  Environment = "production"
  CostCenter  = "engineering"
}
```

## Multi-Region Deployment

To monitor alarms across multiple AWS regions, deploy once per region:

```bash
# US East
terraform workspace new us-east-1
terraform apply -var='aws_region=us-east-1'

# EU West
terraform workspace new eu-west-1
terraform apply -var='aws_region=eu-west-1'
```

## What Alarms Are Subscribed?

The Lambda automatically subscribes **all CloudWatch metric alarms** except:

| Excluded | Reason |
|----------|--------|
| Alarms with `ActionsEnabled = false` | Disabled alarms — no notifications expected |
| Alarms with descriptions starting with `"DO NOT EDIT OR DELETE."` | AWS-managed alarms (e.g., Auto Scaling) |

All other alarms are subscribed, including alarms with custom descriptions or no description.

## Architecture & Security

### Least-Privilege IAM

The Lambda function has only the permissions it needs:

- **CloudWatch**: `DescribeAlarms` (read all), `PutMetricAlarm` (modify alarm actions)
- **SNS**: `Publish` and `ConfirmSubscription` (scoped to the BugRaid topic only)
- **CloudWatch Logs**: Write logs (scoped to the Lambda's log group only)

### SNS Topic Policy

The SNS topic restricts who can publish:
- **CloudWatch service** — delivers alarm notifications
- **Lambda execution role** — manages subscriptions

No other principals can publish to the topic.

### Concurrency Safety

The Lambda has `reserved_concurrent_executions = 1`, ensuring only one instance runs at a time. This prevents race conditions when the EventBridge rule triggers while a previous invocation is still running.

### Data Flow

All alarm data flows over HTTPS. Your webhook URL is marked as sensitive in Terraform and will not appear in plan output or state file diffs.

## Troubleshooting

### "No alarms to update" in Lambda logs

This is normal — it means all alarms are already subscribed to BugRaid. The Lambda runs every 5 minutes and skips alarms that are already connected.

### Alarms not appearing in BugRaid

1. **Check the SNS subscription is confirmed:**
   ```bash
   aws sns list-subscriptions-by-topic \
     --topic-arn "arn:aws:sns:REGION:ACCOUNT:BugRaidTopic-IDENTIFIER"
   ```
   The subscription status should show `Confirmed`, not `PendingConfirmation`.

2. **Check Lambda is running without errors:**
   ```bash
   aws logs tail /aws/lambda/BugRaid-CloudWatch-AddTopic-IDENTIFIER --since 30m
   ```

3. **Trigger a test alarm:**
   ```bash
   aws cloudwatch set-alarm-state \
     --alarm-name "YOUR_ALARM_NAME" \
     --state-value ALARM \
     --state-reason "Testing BugRaid integration"
   ```

### Lambda timeout errors

The Lambda has a 120-second timeout. For accounts with hundreds of alarms, the first run may take longer as it subscribes all existing alarms. Subsequent runs are fast because already-subscribed alarms are skipped.

### Terraform state issues

If you lose your Terraform state, you can safely re-run `terraform apply`. All resources are idempotent — existing resources will be imported or recreated without duplication.

## Uninstalling

To remove all BugRaid resources from your AWS account:

```bash
terraform destroy
```

> **Note:** This removes the SNS topic and Lambda but does not remove the BugRaid topic ARN from individual alarm actions. The stale ARN in alarm actions is harmless — alarms will simply skip the undeliverable action.

## Cost

This integration has minimal AWS cost:

| Resource | Estimated Monthly Cost |
|----------|----------------------|
| Lambda (every 5 min, ~1s per run) | ~$0.00 (within free tier) |
| SNS topic + HTTPS delivery | ~$0.00 (within free tier for typical alarm volume) |
| EventBridge rule | Free |
| **Total** | **< $1/month** |

## Support

- **BugRaid support:** Contact your BugRaid account team or visit [bugraid.ai](https://bugraid.ai)
- **Infrastructure issues:** Open an issue in this repository
