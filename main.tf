terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.48.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

resource "random_pet" "crud_bucket_name" {
  prefix = "perform-crud-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.crud_bucket_name.id

  acl           = "private"
  force_destroy = true
}

# Uploading the code to Archive

data "archive_file" "lambda_crud" {
  type = "zip"

  source_dir = "${path.module}/src"
  output_path = "${path.module}/src.zip"
}

resource "aws_s3_bucket_object" "lambda_crud" {

  bucket = aws_s3_bucket.lambda_bucket.id 

  key = "src.zip"
  source = data.archive_file.lambda_crud.output_path

  etag = filemd5(data.archive_file.lambda_crud.output_path)
  
}

################ Creating Lambda Functions ################

# Add User

resource "aws_lambda_function" "add_user" {
  function_name = "AddUser"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key = aws_s3_bucket_object.lambda_crud.key

  runtime = "python3.8"
  handler = "add_user.handler"

  source_code_hash = data.archive_file.lambda_crud.output_base64sha256

  role = aws_iam_role.dbaccess.arn
}

# Delete User

resource "aws_lambda_function" "delete_user" {
  function_name = "DeleteUser"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key = aws_s3_bucket_object.lambda_crud.key

  runtime = "python3.8"
  handler = "delete_user.handler"

  source_code_hash = data.archive_file.lambda_crud.output_base64sha256

  role = aws_iam_role.dbaccess.arn
}

# Get User

resource "aws_lambda_function" "get_user" {
  function_name = "GetUser"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key = aws_s3_bucket_object.lambda_crud.key

  runtime = "python3.8"
  handler = "get_user.handler"

  source_code_hash = data.archive_file.lambda_crud.output_base64sha256

  role = aws_iam_role.dbaccess.arn
}

#List User

resource "aws_lambda_function" "list_user" {
  function_name = "ListUser"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key = aws_s3_bucket_object.lambda_crud.key

  runtime = "python3.8"
  handler = "list_users.handler"

  source_code_hash = data.archive_file.lambda_crud.output_base64sha256

  role = aws_iam_role.dbaccess.arn
}

# Sync User

resource "aws_lambda_function" "sync_user" {
  function_name = "SyncUser"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key = aws_s3_bucket_object.lambda_crud.key

  runtime = "python3.8"
  handler = "sync_users.handler"

  source_code_hash = data.archive_file.lambda_crud.output_base64sha256

  role = aws_iam_role.dbaccess.arn
}

###### Cloud Watch Group for all Lambda(s) ######

resource "aws_cloudwatch_log_group" "add_user" {
  name = "/aws/lambda/${aws_lambda_function.add_user.function_name}"
  retention_in_days = 30
}
resource "aws_cloudwatch_log_group" "delete_user" {
  name = "/aws/lambda/${aws_lambda_function.delete_user.function_name}"
  retention_in_days = 30
}
resource "aws_cloudwatch_log_group" "get_user" {
  name = "/aws/lambda/${aws_lambda_function.get_user.function_name}"
  retention_in_days = 30
}
resource "aws_cloudwatch_log_group" "list_user" {
  name = "/aws/lambda/${aws_lambda_function.list_user.function_name}"
  retention_in_days = 30
}
resource "aws_cloudwatch_log_group" "sync_user" {
  name = "/aws/lambda/${aws_lambda_function.sync_user.function_name}"
  retention_in_days = 30
}

#### Policy Definition ####

resource "aws_iam_role_policy" "db_policy" {
  name = "db_policy"
  role = aws_iam_role.dbaccess.id

  policy = <<EOF
{  
  "Version": "2012-10-17",
  "Statement":[{
    "Effect": "Allow",
    "Action": [
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "iam:GetRole",
      "iam:DeleteRole",
      "iam:PassRole",
      "iam:DeleteAccountAlias",
      "iam:ListAccessKeys",
      "iam:ListRoles",
      "iam:DeleteUser",
      "iam:UpdateRole",
      "iam:GetUser",
      "iam:DeleteGroup",
      "iam:UpdateGroup",
      "iam:CreateRole",
      "iam:UpdateLoginProfile",
      "iam:GetServerCertificate",
      "iam:CreateGroup",
      "iam:UpdateUser",
      "iam:GetUserPolicy",
      "iam:CreateUser",
      "iam:DeleteLoginProfile",
      "iam:ListUserPolicies",
      "iam:ListInstanceProfiles",
      "iam:UploadServerCertificate",
      "iam:ListPolicyVersions",
      "iam:ListOpenIDConnectProviders",
      "iam:ListUsers",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
      ],
    "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "dbaccess" {
  name = "dbaccess"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF
}

## DynamoDB Creation

resource "aws_dynamodb_table" "ddbtable" {
  name             = "users"
  hash_key         = "UserName"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  attribute {
    name = "UserName"
    type = "S"
  }
}

############################## Creating HTTP API(s) ##############################

resource "aws_apigatewayv2_api" "lambda" {
  name = "serverless_crud_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name = "serverless_crud"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

### List User ###

resource "aws_apigatewayv2_integration" "list_user" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri = aws_lambda_function.list_user.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "list_user" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /list_user"
  target    = "integrations/${aws_apigatewayv2_integration.list_user.id}"
}

resource "aws_lambda_permission" "api_gw1" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_user.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

### Sync User ###

resource "aws_apigatewayv2_integration" "sync_user" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri = aws_lambda_function.sync_user.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "sync_user" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /sync_user"
  target    = "integrations/${aws_apigatewayv2_integration.sync_user.id}"
}

resource "aws_lambda_permission" "api_gw2" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sync_user.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

### Get User ###

resource "aws_apigatewayv2_integration" "get_user" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri = aws_lambda_function.get_user.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "get_user" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /get_user/{UserName}"
  target    = "integrations/${aws_apigatewayv2_integration.get_user.id}"
}

resource "aws_lambda_permission" "api_gw3" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_user.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

### Add User ###

resource "aws_apigatewayv2_integration" "add_user" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri = aws_lambda_function.add_user.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "add_user" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /add_user/{UserName}"
  target    = "integrations/${aws_apigatewayv2_integration.add_user.id}"
}

resource "aws_lambda_permission" "api_gw4" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.add_user.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

### Delete User ###

resource "aws_apigatewayv2_integration" "delete_user" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri = aws_lambda_function.delete_user.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "delete_user" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /delete_user/{UserName}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_user.id}"
}

resource "aws_lambda_permission" "api_gw5" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_user.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}