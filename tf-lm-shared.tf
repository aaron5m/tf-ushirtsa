# SHARED ZIP 

data "archive_file" "lambda_source_zip" {
  type        = "zip"
  source_dir  = "scripts/"
  output_path = "${path.root}/lambda_bundle.zip"
}

# SHARED IAM ROLE

resource "aws_iam_role" "iam_for_lambda" {
  name = "tshirt_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# ADD LOGGING

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SHARED POLICY

resource "aws_iam_role_policy" "lambda_combined_policy" {
  name = "lambda_combined_permissions"
  role = aws_iam_role.iam_for_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowSecrets"
        Action   = ["secretsmanager:GetSecretValue"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid      = "AllowInvoke"
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.lm_order_lambda.arn
      }
    ]
  })
}