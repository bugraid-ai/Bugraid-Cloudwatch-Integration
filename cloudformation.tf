resource "aws_cloudformation_stack" "trigger_codebuild_stack" {
  count = var.subscribe_all && var.daily_event_rule ? 1 : 0
  name = "trigger-codebuild-stack3"
  parameters = {
    bugraidlambdafunctionArn = aws_lambda_function.process_cloudwatch_events[0].arn
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
      "Type" : "String"
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
  }
}
STACK
}