resource "aws_cloudformation_stack" "trigger_codebuild_stack" {
  count = var.subscribe_all ? 1 : 0
  name = "${var.project_name}-trigger-codebuild-${var.environment}"
  
  parameters = {
    bugraidlambdafunctionArn = var.daily_event_rule ? aws_lambda_function.process_cloudwatch_events[0].arn : ""
    SubscribeAll              = var.subscribe_all
  }

  template_body = <<STACK
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Parameters" : {
    "SubscribeAll" : {
      "Type" : "String",
      "Description" : "Setting this to 'true' will automatically add the Bugraid Topic to all existing CloudWatch Alarms"
    },
    "bugraidlambdafunctionArn" : {
      "Type" : "String",
      "Description" : "ARN of the BugRaid Lambda function"
    }
  },
  "Conditions": {
    "SubscribeToAlarms": {
      "Fn::Equals": [
        {
          "Ref": "SubscribeAll"
        },
        "true"
      ]
    },
    "HasLambdaArn": {
      "Fn::Not": [
        {
          "Fn::Equals": [
            {
              "Ref": "bugraidlambdafunctionArn"
            },
            ""
          ]
        }
      ]
    }
  },
  "Resources" : {
    "BugRaidInvokeLambda": {
      "Type" : "AWS::CloudFormation::CustomResource",
      "Properties" : {
        "ServiceToken" : {
          "Ref" : "bugraidlambdafunctionArn"
        }
      },
      "Condition": "SubscribeToAlarms"
    }
  },
  "Outputs": {
    "StackStatus": {
      "Description": "Status of the CloudFormation stack",
      "Value": {
        "Ref": "AWS::StackId"
      }
    }
  }
}
STACK

  tags = {
    Name        = "${var.project_name}-cloudformation-stack"
    Environment = var.environment
    Project     = var.project_name
  }
}