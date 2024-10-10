variable "vpce_id" {
  description = "The ID of the VPC endpoint to be used in the API Gateway resource policy"
  type        = string
}

variable "project_name" {
  description = "this is the project we are building"
  type        = string
}

variable "lambda_arn" {
  description = "this is the ARN of the lambda we want to integrate"
  type        = string
}

variable "lambda_name" {
  description = "The name of the Lambda function"
  type        = string
}
  