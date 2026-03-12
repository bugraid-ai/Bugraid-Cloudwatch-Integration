resource "aws_cloudformation_stack" "trigger_codebuild_stack" {
  count = 0 # Temporarily disabled due to stuck stack
  name  = "bugraid-subscribe-stack-${var.identifier}"
  parameters = {
    bugraidlambdafunctionArn = aws_lambda_function.process_cloudwatch_events[0].arn
  }

  template_body = <<STACK
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Parameters" : {
    "bugraidlambdafunctionArn" : {
      "Type" : "String"
    }
  },
  "Resources" : {
    "BugRaidAIInvokeLambda": {
      "Type" : "AWS::CloudFormation::CustomResource",
      "Properties" : {
        "ServiceToken" : {
          "Ref" : "bugraidlambdafunctionArn"
        }
      }
    }
  }
}
STACK

  tags = merge(var.tags, {
    Name        = "bugraid-subscribe-stack-${var.identifier}"
    ManagedBy   = "bugraid"
    Environment = var.identifier
  })
}
