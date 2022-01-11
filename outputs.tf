# Output value definitions

output "lambda_bucket_name" {
  description = "Name of the S3 bucket used to store function code."

  value = aws_s3_bucket.lambda_bucket.id
}

# Lambda Function Outputs

output "add_user" {
  description = "Adds User"

  value = aws_lambda_function.add_user.function_name
}

output "delete_user" {
  description = "Deletes User"

  value = aws_lambda_function.delete_user.function_name
}

output "get_user" {
  description = "Gets the User"

  value = aws_lambda_function.get_user.function_name
}

output "list_user" {
  description = "Lists User"

  value = aws_lambda_function.list_user.function_name
}

output "sync_user" {
  description = "Syncs User"

  value = aws_lambda_function.sync_user.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.lambda.invoke_url
}
