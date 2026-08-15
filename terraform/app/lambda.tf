data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/bootstrap"
  output_path = "${path.module}/../../lambda/function.zip"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-contact-lambda-role"

  assume_role_policy = jsonencode({
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

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-contact-lambda-policy"
  description = "Allows Lambda to send emails via SES and write CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "contact_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-contact-backend"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  architectures    = ["arm64"]
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      SENDER_EMAIL = "danoguer.dev@gmail.com"
    }
  }
}

resource "aws_lambda_function_url" "contact_url" {
  function_name      = aws_lambda_function.contact_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["content-type"]
    max_age           = 86400
  }
}

output "contact_lambda_url" {
  description = "URL pública para invocar la Lambda desde el Frontend"
  value       = aws_lambda_function_url.contact_url.function_url
}
