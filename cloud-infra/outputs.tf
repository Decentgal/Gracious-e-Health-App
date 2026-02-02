output "gracy_kms_key_arn" { value = aws_kms_key.gracy_key.arn }
output "gracy_secret_arn" { value = aws_secretsmanager_secret.gracy_db_secret.arn }