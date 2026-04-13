# LAMBDA FUNCTION 

resource "aws_lambda_function" "lm_payment_lambda" {
  function_name = "payment-handler"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lm-payment.handler"
  runtime       = "nodejs24.x"
  timeout       = 60
  filename         = data.archive_file.lambda_source_zip.output_path
  source_code_hash = data.archive_file.lambda_source_zip.output_base64sha256
  environment {
    variables = {
      printful_store_id = var.printful_store_id,
      INTERNAL_API_KEY  = var.INTERNAL_API_KEY,
      PRINTFUL_API_KEY  = var.PRINTFUL_API_KEY
      STRIPE_SECRET_KEY = var.STRIPE_SECRET_KEY
    }
  }
}

# LAMBDA URL

resource "aws_lambda_function_url" "lm_payment_url" {
  function_name      = aws_lambda_function.lm_payment_lambda.function_name
  authorization_type = "NONE"
}

# OUTPUT

output "lambda_payment_url" {
  value = aws_lambda_function_url.lm_payment_url.function_url
}