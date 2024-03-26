module "s3-fe" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = "nolyporp-${var.environment}-fe"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  force_destroy = true

  versioning = {
    enabled = true
  }
}
