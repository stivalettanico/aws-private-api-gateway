output "lambda_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.lambda_function.invoke_arn
}

output "lambda_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.lambda_function.function_name
}