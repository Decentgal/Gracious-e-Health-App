# 1. KMS Key for Encryption
resource "aws_kms_key" "gracy_key" {
  description             = "KMS Key for My e-Health app"
  deletion_window_in_days = 7
  enable_key_rotation     = true 
  tags                    = { Name = "Gracy-KMS" }
}

resource "aws_kms_key_policy" "gracy_key_default" {
  key_id = aws_kms_key.gracy_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          # FIXED: Replace with your specific ARN for high-level security
          AWS = "arn:aws:iam::996353668285:user/Gracy-DevOps-Admin"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# 2. Secret Manager
resource "aws_secretsmanager_secret" "gracy_db_secret" {
  name                    = "Gracy-App-Secrets"
  kms_key_id              = aws_kms_key.gracy_key.arn
  recovery_window_in_days = 0
}

# 3. REAL Lambda Rotation (No more placeholders)
resource "aws_iam_role" "lambda_exec_role" {
  name = "gracy_lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# ZIP the local python file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/rotation_lambda.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

resource "aws_lambda_function" "gracy_rotator" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "Gracy-Secret-Rotator"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "rotation_lambda.lambda_handler"
  runtime       = "python3.11"
}

# Link rotation to the real Lambda ARN
resource "aws_secretsmanager_secret_rotation" "gracy_db_rotation" {
  secret_id           = aws_secretsmanager_secret.gracy_db_secret.id
  rotation_lambda_arn = aws_lambda_function.gracy_rotator.arn 
  
  rotation_rules {
    automatically_after_days = 30
  }
}

# Permission for Secrets Manager to trigger Lambda
resource "aws_lambda_permission" "allow_secrets" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gracy_rotator.function_name
  principal     = "secretsmanager.amazonaws.com"
}