resource "aws_secretsmanager_secret" "aws_s3_key" {
  name        = "${var.environment}"
  description = "aws_s3_key_${var.environment}"
}

resource "aws_secretsmanager_secret_version" "aws_s3_key" {
  secret_id     = aws_secretsmanager_secret.aws_s3_key.id
  secret_string = file("~/.passwd-s3fs")
}

data "aws_secretsmanager_secret_version" "aws_s3_key" {
  secret_id = aws_secretsmanager_secret.aws_s3_key.id
  depends_on = [
    aws_secretsmanager_secret_version.aws_s3_key
  ]
}

# resource "aws_secretsmanager_secret" "aws_s3_secret_key" {
#   name        = "aws_s3_secret_key_${var.environment}"
#   description = "aws_s3_secret_key_${var.environment}"
# }

# resource "aws_secretsmanager_secret_version" "aws_s3_secret_key" {
#   secret_id     = aws_secretsmanager_secret.aws_s3_secret_key.id
#   secret_string = "CHANGE IT" # update the real value in AWS SecretsManager once the resource is created
# }

# data "aws_secretsmanager_secret_version" "aws_s3_secret_key" {
#   secret_id = aws_secretsmanager_secret.aws_s3_secret_key.id
#   depends_on = [
#     aws_secretsmanager_secret_version.aws_s3_secret_key
#   ]
# }
