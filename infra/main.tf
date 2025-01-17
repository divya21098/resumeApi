resource "aws_lambda_function" "movies_lambda" {
  filename         = data.archive_file.zip_the_python_code.output_path
  source_code_hash = data.archive_file.zip_the_python_code.output_base64sha256
  function_name    = "serverless-lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "serverless-lambda.lambda_handler"
  runtime          = "python3.9"
}
# DynamoDB table
resource "aws_dynamodb_table" "movies_table" {
  name         = "Movies-API"
  hash_key     = "title"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "title"
    type = "S"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

# IAM policy for Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "dynamo_db_read_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "api_gateway_invoke" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
}


# Attach policy to role

# API Gateway
# Create the API Gateway to connect to the Lambda function
resource "aws_api_gateway_rest_api" "movies_api" {
  name        = "Movies API"
  description = "API Gateway to trigger Lambda functions for getting movies"
}

# Create the /get_movies resource
resource "aws_api_gateway_resource" "get_movies_resource" {
  rest_api_id = aws_api_gateway_rest_api.movies_api.id
  parent_id   = aws_api_gateway_rest_api.movies_api.root_resource_id
  path_part   = "get_movies"
}

# Create the /get_movies_by_year resource
resource "aws_api_gateway_resource" "get_movies_by_year_resource" {
  rest_api_id = aws_api_gateway_rest_api.movies_api.id
  parent_id   = aws_api_gateway_rest_api.movies_api.root_resource_id
  path_part   = "get_movies_by_year"
}

# Create GET method for /get_movies
resource "aws_api_gateway_method" "get_movies_method" {
  rest_api_id   = aws_api_gateway_rest_api.movies_api.id
  resource_id   = aws_api_gateway_resource.get_movies_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integrate GET /get_movies with the Lambda function
resource "aws_api_gateway_integration" "get_movies_integration" {
  rest_api_id             = aws_api_gateway_rest_api.movies_api.id
  resource_id             = aws_api_gateway_resource.get_movies_resource.id
  http_method             = aws_api_gateway_method.get_movies_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-west-1:lambda:path/2015-03-31/functions/${aws_lambda_function.movies_lambda.arn}/invocations"
}

# Create GET method for /get_movies_by_year
resource "aws_api_gateway_method" "get_movies_by_year_method" {
  rest_api_id   = aws_api_gateway_rest_api.movies_api.id
  resource_id   = aws_api_gateway_resource.get_movies_by_year_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integrate GET /get_movies_by_year with the Lambda function
resource "aws_api_gateway_integration" "get_movies_by_year_integration" {
  rest_api_id             = aws_api_gateway_rest_api.movies_api.id
  resource_id             = aws_api_gateway_resource.get_movies_by_year_resource.id
  http_method             = aws_api_gateway_method.get_movies_by_year_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-west-1:lambda:path/2015-03-31/functions/${aws_lambda_function.movies_lambda.arn}/invocations"
}

# Grant API Gateway permission to invoke Lambda
resource "aws_lambda_permission" "allow_api_gateway_get_movies" {
  statement_id  = "AllowAPIGatewayInvokeGetMovies"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.movies_lambda.function_name
  source_arn    = "${aws_api_gateway_rest_api.movies_api.execution_arn}/*/GET/get_movies"
}

resource "aws_lambda_permission" "allow_api_gateway_get_movies_by_year" {
  statement_id  = "AllowAPIGatewayInvokeGetMoviesByYear"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.movies_lambda.function_name
  source_arn    = "${aws_api_gateway_rest_api.movies_api.execution_arn}/*/GET/get_movies_by_year"
}

# Deploy the API
resource "aws_api_gateway_deployment" "movies_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.get_movies_integration,
    aws_api_gateway_integration.get_movies_by_year_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.movies_api.id
  stage_name  = "prod"
}

output "api_gateway_invoke_url" {
  value = "https://${aws_api_gateway_rest_api.movies_api.id}.execute-api.us-west-1.amazonaws.com/prod"
}

# resource "aws_api_gateway_deployment" "api_deployment" {
#   rest_api_id = aws_api_gateway_rest_api.movies_api.id
#   stage_name  = "prod"
# }
# resource "aws_iam_role" "iam_for_lambda" {
#   name = "iam_for_lambda"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#         Effect = "Allow"
#         Sid    = ""
#       }
#     ]
#   })
# }

# resource "aws_iam_policy" "iam_policy_for_serverless_lambda" {

#   name        = "aws_iam_policy_for_serverless_lambda"
#   path        = "/"
#   description = "AWS IAM Policy for managing the serverless lambda function"
#   policy = jsonencode(
#     {
#       Version : "2012-10-17",
#       Statement : [
#         {
#           Action : [
#             "logs:CreateLogGroup",
#             "logs:CreateLogStream",
#             "logs:PutLogEvents"
#           ]
#           Resource : "arn:aws:logs:*:*:*",
#           Effect : "Allow"
#         },
#         {
#           Effect : "Allow"
#           Action : [
#             "s3:GetObject",
#             "s3:ListBucket"
#           ]
#           Resource = [
#             "arn:aws:s3:::serverless-resume-bucket",
#             "arn:aws:s3:::serverless-resume-bucket/*"
#           ]
#         },
#       ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
#   role       = aws_iam_role.iam_for_lambda.name
#   policy_arn = aws_iam_policy.iam_policy_for_serverless_lambda.arn
# }

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_file = "${path.module}/lambda/serverless-lambda.py"
  output_path = "${path.module}/lambda/serverless-lambda.zip"
}

# # resource "aws_s3_bucket" "serverless_bucket" {

# #   bucket = "divyabucket0210"
  
# # }

# # resource "aws_s3_object" "serverless_bucket_object" {
# #   bucket = aws_s3_bucket.serverless_bucket.id
# #   key    = "movie.json"
# #   source = "${path.module}/movie.json"
# # }

# resource "aws_api_gateway_rest_api" "my-api-gw" {
#   name        = "serverless-api-gw"
#   description = "Example REST API for demonstration purposes"
#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
# }

# resource "aws_api_gateway_resource" "my-api-gw-resource" {
#   rest_api_id = aws_api_gateway_rest_api.my-api-gw.id
#   parent_id   = aws_api_gateway_rest_api.my-api-gw.root_resource_id
#   path_part   = "serverless-api-gw"
# }

# resource "aws_api_gateway_method" "get_method" {
#   rest_api_id   = aws_api_gateway_rest_api.my-api-gw.id
#   resource_id   = aws_api_gateway_resource.my-api-gw-resource.id
#   http_method   = "GET"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "integration" {
#   rest_api_id             = aws_api_gateway_rest_api.my-api-gw.id
#   resource_id             = aws_api_gateway_resource.my-api-gw-resource.id
#   http_method             = aws_api_gateway_method.get_method.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.myfunc.invoke_arn
# }

# resource "aws_lambda_permission" "apigw_lambda_permission" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.myfunc.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.my-api-gw.execution_arn}/dev/GET/*"
# }

# resource "aws_api_gateway_stage" "api-gw-stage" {
#   rest_api_id   = aws_api_gateway_rest_api.my-api-gw.id
#   deployment_id = aws_api_gateway_deployment.api-gw-deployment.id
#   stage_name    = "dev"
# }

# resource "aws_api_gateway_deployment" "api-gw-deployment" {
#   rest_api_id = aws_api_gateway_rest_api.my-api-gw.id


#   lifecycle {
#     create_before_destroy = true
#   }

#   depends_on = [
#     aws_api_gateway_integration.integration, aws_api_gateway_method.get_method
#   ]

# }