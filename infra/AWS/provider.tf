terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

########################## Default region ##########################
provider "aws" {
  region                   = "eu-central-1"
  shared_credentials_files = ["~/.aws/credentials_nolyporp"]
}

######################### Store Terraform state file into S3 bucket ##########################
# terraform {
#   backend "s3" {
#     profile        = "default"
#     bucket         = "nolyporp-terraform-state"
#     key            = "terraform.tfstate"
#     region         = "eu-central-1"
#     dynamodb_table = "nolyporp-terraform-state-lock"
#   }
# }

########################## aws_caller_identity ##########################
data "aws_caller_identity" "current" {}

########################## aws_region ##########################
data "aws_region" "current" {}

########################## aws_availability_zones ##########################
data "aws_availability_zones" "available" {
  state = "available"
}

module "s3_tf_state" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = "nolyporp-terraform-state"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  force_destroy = true

  versioning = {
    enabled = true
  }
}

################## Dynamo Table Lock ##################
resource "aws_dynamodb_table" "terraform-state" {
  name           = "nolyporp-terraform-state-lock"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }
}
