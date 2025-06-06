provider "aws" {
    region = "us-east-1"
}

// Create a unique S3 bucket for Lambda triggers using a random suffix
resource "aws_s3_bucket" "bucket" {
    bucket = "my-lambda-trigger-bucket-${random_id.id.hex}"
}

// Generate a random ID for unique resource naming
resource "random_id" "id" {
    byte_length = 4
}

// Create an IAM role for Lambda with permissions to be assumed by Lambda service
resource "aws_iam_role" "lambda_exec" {
    name = "lambda_exec_role"
    assume_role_policy  = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "lambda.amazonaws.com"
            }
        }]
    })
}

// Deploy the Lambda function using the specified IAM role and code package
resource "aws_lambda_function" "lambda" {
    function_name = "S3LambdaHandler"
    role = aws_iam_role.lambda_exec.arn
    handler = "lambda_function.lambda_handler"
    runtime = "python3.12"
    filename         = "${path.module}/../lambda/lambda_function.zip"
    source_code_hash = filebase64sha256("${path.module}/../lambda/lambda_function.zip")
}

// Configure S3 bucket to send notifications to Lambda on object creation events
resource "aws_s3_bucket_notification" "notify" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  // Ensure Lambda permission is created before notification
  depends_on = [aws_lambda_permission.allow_s3]
}

// Allow S3 to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

//add permissions to view cloudwatch logs 
resource "aws_iam_role_policy" "lambda_logs" {
  name = "lambda-logs"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "lambda-s3-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
          ]
      }
    ],
    Resource= [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*"
    ]

  })
}


 