data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Define the API Gateway
resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.project_name}-${terraform.workspace}"
  description = "Private API Gateway with restricted access"
  endpoint_configuration {
    types = ["PRIVATE"]
  }
}

# Load the policy from the external file and replace placeholders dynamically
resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  policy = templatefile("${path.module}/files/api_gateway_policy.json", {
    vpce_id    = var.vpce_id,
    region     = data.aws_region.current.name,
    account_id = data.aws_caller_identity.current.account_id,
    api_id     = aws_api_gateway_rest_api.this.id
  })
}

# Create an API Gateway resource
resource "aws_api_gateway_resource" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "my-resource"
}

# Define the integration for the method (Mock Integration as an example)
resource "aws_api_gateway_integration" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method
  #Lambda functions can only be invoked by using the method POST. Other methods won't work
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_arn

}

# Create a method for the resource
resource "aws_api_gateway_method" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/${aws_api_gateway_method.this.http_method}${aws_api_gateway_resource.this.path}"

}

# Create a deployment for the API
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = terraform.workspace

  # Optional trigger: redeploy when the method or resource changes
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_method.this))
  }

  # Depends on the method creation
  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_rest_api_policy.this
  ]
}

