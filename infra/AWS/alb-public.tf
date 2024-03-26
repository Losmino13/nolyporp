resource "aws_lb" "nginx" {
  name               = "nginx-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.frontend.id]
  subnets            = flatten([module.vpc.public_subnets])

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "nginx" {
  name     = "nginx-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id
}
resource "aws_lb_target_group_attachment" "nginx" {
  target_group_arn = aws_lb_target_group.nginx.arn
  target_id        = module.ec2_instances.id
  port             = 80
}
resource "aws_lb_listener" "nginx" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

# module "alb_public" {
#   source = "terraform-aws-modules/alb/aws"

#   name                       = "nolyporp-alb-${var.environment}"
#   vpc_id                     = module.vpc.vpc_id
#   subnets                    = flatten([module.vpc.public_subnets])
#   enable_deletion_protection = false

#   # Security Group
#   security_group_ingress_rules = {
#     all_http = {
#       from_port   = 80
#       to_port     = 80
#       ip_protocol = "tcp"
#       description = "HTTP web traffic"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#     all_https = {
#       from_port   = 443
#       to_port     = 443
#       ip_protocol = "tcp"
#       description = "HTTPS web traffic"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#   }
#   security_group_egress_rules = {
#     all = {
#       ip_protocol = "-1"
#       cidr_ipv4   = "10.0.0.0/16"
#     }
#   }

#   #   access_logs = {
#   #     bucket = "my-alb-logs"
#   #   }

#   listeners = {
#     http = {
#       port     = 80
#       protocol = "HTTP"

#       forward = {
#         target_group_key = "instance"
#       }
#     }
#     # http-https-redirect = {
#     #   port     = 80
#     #   protocol = "HTTP"
#     #   redirect = {
#     #     port        = "443"
#     #     protocol    = "HTTPS"
#     #     status_code = "HTTP_301"
#     #   }
#     # }
#     # https = {
#     #   port            = 443
#     #   protocol        = "HTTPS"
#     #   certificate_arn = "arn:aws:iam::123456789012:server-certificate/nginx_cert-123456789012"

#     #   forward = {
#     #     target_group_key = "instance"
#     #   }
#     # }
#   }

#   target_groups = {
#     instance = {
#       name_prefix = "nginx"
#       protocol    = "HTTP"
#       port        = 80
#       target_type = "instance"
#       target_id   = module.ec2_instances.id
#     }
#   }

#   tags = {
#     Environment = "${var.environment}"
#   }
# }
