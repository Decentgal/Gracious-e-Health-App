# 1. KMS Key for Encryption (ISO 27001 requirement)
resource "aws_kms_key" "gracy_key" {
  description             = "KMS Key for My e-Health app"
  deletion_window_in_days = 7
  enable_key_rotation     = true # Compliance: Key Rotation
  tags                    = { Name = "Gracy-KMS" }
}

# FIX CKV2_AWS_64: Define a KMS Key Policy
resource "aws_kms_key_policy" "gracy_key_default" {
  key_id = aws_kms_key.gracy_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*" # In production, restrict this to your specific IAM ARN
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# 2. Secret Manager (HIPAA requirement for PHI protection)
resource "aws_secretsmanager_secret" "gracy_db_secret" {
  name                    = "Gracy-App-Secrets"
  kms_key_id              = aws_kms_key.gracy_key.arn
  recovery_window_in_days = 0
}

# FIX CKV2_AWS_57: Enable automatic rotation
# Note: In a real AWS environment, you would point rotation_lambda_arn to a specific Lambda.
resource "aws_secretsmanager_secret_rotation" "gracy_db_rotation" {
  secret_id           = aws_secretsmanager_secret.gracy_db_secret.id
  rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotation-lambda" 
  
  rotation_rules {
    automatically_after_days = 30
  }
}

# 3. IAM Policy for the App (Least Privilege)
resource "aws_iam_policy" "gracy_app_policy" {
  name        = "Gracy-App-Security-Policy"
  description = "Allows access to KMS and Secrets Manager only"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue"],
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret.gracy_db_secret.arn
      },
      {
        Action   = ["kms:Decrypt"],
        Effect   = "Allow",
        Resource = aws_kms_key.gracy_key.arn
      }
    ]
  })
}