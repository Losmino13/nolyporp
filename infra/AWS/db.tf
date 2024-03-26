########################## Security Groups for DB ##########################
resource "aws_security_group" "db" {
  name   = "${var.environment}-db"
  vpc_id = module.vpc.vpc_id
  description = "Managed by Terraform - Security Group for the RDS"

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = "${var.private_subnets}"
    description = "Managed by Terraform - Allow private subnet and VPN"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Managed by Terraform - Allow all egress traffic"
  }

}
