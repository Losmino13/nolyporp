locals {
  instance_count    = 3
  instance_suffixes = ["1", "2", "3"]
}
resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2_key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK1X6fqmXtj0WR2zUsXq82A61SFALL8fB3dmHlE+53ID milisavljevic.milos@yahoo.com"
}
module "ec2_instances" {
  source = "terraform-aws-modules/ec2-instance/aws"

  # count = local.instance_count
  #name                        = "nolyporp-${var.environment}-${local.instance_suffixes[count.index]}"
  name                        = "nolyporp"
  ami                         = var.ubuntu_22_04_lts_ami
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ec2_key.id
  monitoring                  = false
  associate_public_ip_address = true

  subnet_id              = element(flatten([module.vpc.public_subnets]), 0)
  # subnet_id              = module.vpc.public_subnets[count.index]
  vpc_security_group_ids = [aws_security_group.frontend.id]

  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"

  user_data = file("./files/user_data.tpl")

  root_block_device = [
    {
      delete_on_termination = "true"
      encrypted             = "true"
      volume_size           = "20"
      volume_type           = "gp2"
    },
  ]

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
  }

  depends_on = [
    aws_security_group.frontend,
    module.vpc
  ]
}


# SG
resource "aws_security_group" "frontend" {
  name   = "${var.environment}-nolyporp"
  vpc_id = module.vpc.vpc_id
  tags = {
    "Name" = "${var.environment}-frontend"
  }
  description = "Managed by Terraform - frontend security group"
}

# Ingress
resource "aws_security_group_rule" "frontend-allow-http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "Managed by Terraform - Allow HTTP"
}

resource "aws_security_group_rule" "frontend-allow-https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "Managed by Terraform - Allow HTTPS"
}

# Egress
resource "aws_security_group_rule" "frontend-allow-all-out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "Managed by Terraform - Allow all egress traffic"
}

# Create an IAM policy allowing  access to S3
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_full_access" {
  statement {
    actions = ["s3:*"]

    resources = ["arn:aws:s3:::*"]
  }
}

resource "aws_iam_role" "ec2_iam_role" {
  name = "ec2_iam_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "ec2_s3_policy"
  role = aws_iam_role.ec2_iam_role.name

  policy = data.aws_iam_policy_document.s3_full_access.json

  depends_on = [aws_iam_role.ec2_iam_role]
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_iam_role.name
}
###################### Policy Attachments #########################
resource "aws_iam_role_policy_attachment" "ec2-ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_iam_role.name
}
resource "aws_iam_role_policy_attachment" "ec2-secrets" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.ec2_iam_role.name
}

