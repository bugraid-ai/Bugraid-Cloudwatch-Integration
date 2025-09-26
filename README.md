# BugRaid CloudWatch Integration (CloudFormation)

This repository provides an **AWS CloudFormation (CFT)** version of the existing Terraform integration for **BugRaid CloudWatch Integration**.  
It provisions the same set of resources as the Terraform scripts, but using CloudFormation templates, making it easier for teams who prefer CFT-based deployments.



## 📌 What This Repo Does

The templates deploy a **CloudWatch → SNS → Lambda → BugRaid Webhook** integration pipeline:

1. **CloudWatch Alarms**  
   Detect state changes (OK → ALARM, ALARM → OK, etc.).

2. **SNS Topic (`${ProjectName}-topic-${Environment}`)**  
   Acts as a hub for alarm notifications.  
   A subscription forwards these notifications to the BugRaid webhook URL.

3. **Lambda Function (`${ProjectName}-cloudwatch-addtopic-${Environment}`)**  
   Processes CloudWatch events and ensures alarms are correctly subscribed.  
   Uses the uploaded `CloudwatchBugRaidAddTopic.zip` code package.

4. **CloudWatch Event Rule**  
   Optionally runs the Lambda on a fixed schedule (`rate(2 minutes)` by default).  
   Ensures subscriptions remain up to date.

5. **Nested CloudFormation Stack (`subscribe-all.yaml`)**  
   If enabled (`SubscribeAll=true`), automatically links **all existing CloudWatch alarms** to the BugRaid SNS topic.



## 🖥️ How It Shows in AWS Console

After a successful deployment, you will see:

- **SNS Console** → A topic named `bugraid-topic-test` (or according to your parameters)  
- **Lambda Console** → A Lambda function named `bugraid-cloudwatch-addtopic-test`  
- **CloudWatch → Rules** → A rule named `bugraid-cloudwatch-event-test` (if DailyEventRule enabled)  
- **CloudFormation Console** → A parent stack and a nested stack (`subscribe-all`)  

This matches the Terraform version but is now fully managed via CFT.



## 🚀 How to Use

### 1. Clone the Repo
```bash
git clone -b test https://github.com/bugraid-ai/Bugraid-Cloudwatch-Integration.git
cd Bugraid-Cloudwatch-Integration

```
### 2. Configure AWS CLI
```bash
aws configure
# Enter Access Key, Secret, Region (e.g. us-west-2), and output format (json)

```
### 3. Upload Lambda Code + Nested Template to S3
```bash
aws s3 mb s3://cloudwatch-integration-cft-test-bucket --region us-west-1  #change the region 
aws s3 cp CloudwatchBugRaidAddTopic.zip s3://cloudwatch-integration-cft-test-bucket/
aws s3 cp subscribe-all.yaml s3://cloudwatch-integration-cft-test-bucket/

```
### 4. Deploy the CloudFormation Stack
```bash
aws cloudformation deploy \
  --template-file cloudwatch-integration-cft-test.yaml \
  --stack-name cloudwatch-cft-test \
  --region us-west-1 \                                #change the region while testing
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      ProjectName=bugraid \
      Environment=test \
      SubscribeAll=true \
      DailyEventRule=true \
      LambdaTimeout=300 \
      WebhookEndpointsUrl=https://example.com/dummy-webhook \     #use actual end-point
      LambdaCodeBucket=cloudwatch-integration-cft-test-bucket \   #change name as needed
      LambdaCodeKey=CloudwatchBugRaidAddTopic.zip

```
### 4. Delete the CloudFormation Stack
```bash
aws cloudformation delete-stack \
  --stack-name cloudwatch-cft-test \
  --region us-west-1      #change the region while testing

```
⚙️ Parameters

ProjectName → Used for resource naming (bugraid by default)

Environment → dev, test, prod

SubscribeAll → true/false (auto-subscribe all alarms)

DailyEventRule → true/false (run Lambda on schedule)

WebhookEndpointsUrl → HTTPS URL of BugRaid webhook (replace dummy later)

LambdaTimeout → Timeout for Lambda (default 300s)

LambdaCodeBucket → S3 bucket containing Lambda zip

LambdaCodeKey → Name of the Lambda zip file in S3

## ✅ In short: This repo is the CFT equivalent of the Terraform integration, showing up in SNS, Lambda, CloudWatch, and CloudFormation consoles after deployment.
Teams only need to adjust the Webhook URL and deployment parameters when reusing.

## ⚡ Note on Naming
The --stack-name parameter only defines the name of the CloudFormation stack itself (the container in AWS). It does not control the names of the resources inside. Resource names (SNS topic, Lambda, IAM roles, etc.) are driven by the ProjectName and Environment parameters. The defaults in the template are just fallbacks — whenever you pass new values through --parameter-overrides, those will override the defaults and resources will be created with the new names. For example, using ProjectName=mytest and Environment=staging will produce resources like mytest-topic-staging and mytest-lambda-exec-role-staging, regardless of the template’s default values.
