terraform {
  required_providers {
    archive = "~> 1.3"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/python/main.py"
  output_path = "${path.module}/python/main.py.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename         = "${path.module}/python/main.py.zip"
  function_name    = var.lambdaname
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("${path.module}/python/main.py.zip")
  timeout          = 300
  environment {
    variables = {
      REGION = var.region
    }
  }
}

resource "aws_cloudwatch_event_rule" "every_one_minute" {
  name                = "${var.lambdaname}-event-rule"
  description         = "7-00 PM Monday through Fridays"
  schedule_expression = "cron(0 22 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "check_foo_every_one_minute" {
  rule      = aws_cloudwatch_event_rule.every_one_minute.name
  target_id = "lambda"
  arn       = aws_lambda_function.test_lambda.arn
}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_one_minute.arn
}
