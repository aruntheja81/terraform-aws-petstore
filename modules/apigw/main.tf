data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.namespace}-api"
  description = "This api proxies all request to a lambda handler"
}

#apigw role
data "aws_iam_policy_document" "api_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigw_role" {
  name               = "cloudwatch-role-${var.namespace}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.api_assume_role_policy_document.json
}

data "aws_iam_policy_document" "logger_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:*",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_policy" "logger_policy" {
  name   = "apigw-logger-${var.namespace}"
  path   = "/"
  policy = data.aws_iam_policy_document.logger_policy_document.json
}

resource "aws_iam_policy_attachment" "logger_role_attachment" {
  name       = "apigw-logger-attachment-${var.namespace}"
  roles      = [aws_iam_role.apigw_role.name]
  policy_arn = aws_iam_policy.logger_policy.arn
}

resource "aws_api_gateway_account" "cloudwatch_apigw_logs" {
  cloudwatch_role_arn = aws_iam_role.apigw_role.arn
}

resource "aws_lambda_permission" "lambda_permission_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/*"
}

#GET / (redirects to /ui)
resource "aws_api_gateway_method" "redirect_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "redirect_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.redirect_method.http_method 
  type = "MOCK"
}

resource "aws_api_gateway_method_response" "redirect" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.redirect_method.http_method 

  response_parameters = {
    "method.response.header.Location" = true
  }

  status_code = "302"
}

resource "aws_api_gateway_integration_response" "redirect_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.redirect_method.http_method 
  status_code = aws_api_gateway_method_response.redirect.status_code 

  response_parameters = {
    "method.response.header.Location" = "'/v1/ui'"
  }
}

# /{proxy+}
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

#ANY /{proxy+}
resource "aws_api_gateway_method" "auth_any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "any_method_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.auth_any.http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.lambda_arn}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_resource.proxy,
    aws_api_gateway_method.auth_any,
    aws_api_gateway_integration.any_method_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "v1"
}