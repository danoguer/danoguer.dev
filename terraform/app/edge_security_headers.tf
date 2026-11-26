data "archive_file" "edge_security_headers" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/edge_security_headers/index.js"
  output_path = "${path.module}/../../lambda/edge_security_headers.zip"
}

resource "aws_iam_role" "edge_security_headers" {
  name = "${var.project_name}-edge-security-headers-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "edgelambda.amazonaws.com",
          "lambda.amazonaws.com"
        ]
      }
    }]
  })
}

resource "aws_iam_role_policy" "edge_security_headers_logs" {
  name = "${var.project_name}-edge-security-headers-logs"
  role = aws_iam_role.edge_security_headers.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-edge-security-headers:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-edge-security-headers:log-stream:*"
      }
    ]
  })
}

resource "aws_lambda_function" "edge_security_headers" {
  provider         = aws.us_east_1
  filename         = data.archive_file.edge_security_headers.output_path
  function_name    = "${var.project_name}-edge-security-headers"
  role             = aws_iam_role.edge_security_headers.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  source_code_hash = data.archive_file.edge_security_headers.output_base64sha256
  timeout          = 5
  memory_size      = 128
  publish          = true

  depends_on = [
    aws_iam_role_policy.edge_security_headers_logs
  ]
}

resource "aws_lambda_permission" "edge_security_headers_cloudfront" {
  provider       = aws.us_east_1
  statement_id   = "AllowCloudFrontEdgeInvocation"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.edge_security_headers.function_name
  qualifier      = aws_lambda_function.edge_security_headers.version
  principal      = "edgelambda.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}
