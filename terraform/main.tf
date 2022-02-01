
### Collect existing subnets to use for Application Load balancer
data "aws_subnet" "subnets" {
  for_each           = toset(var.availability_zones)
  vpc_id             = var.vpc_id
  availability_zone  = each.value
}


### Create the ALB  web entrypoint, switching its internal attribute to false to expose it.
resource "aws_lb" "alb" {
  name               = var.alb.alb_name      # diag-alb
  internal           = var.alb.internal      # false
  load_balancer_type = "application"
  subnets            = [for s in data.aws_subnet.subnets : s.id]
#  access_logs {
#    bucket = "diag-alb-logs"
#    prefix  = "diag-lb"
#    enabled = true
#  }

  tags = {
    Environment = var.environment
  }
}

### Create Load balancer target group
resource "aws_lb_target_group" "alb-diag-tg" {
  name                 = "${var.alb.alb_name}-tg"
  port                 = 8000
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = var.deregistration_delay
  target_type          = "ip"
  health_check {
    path     = var.health_check_path
    protocol = "HTTP"
  }
  depends_on            = [aws_lb.alb]

  tags = {
    Environment = var.environment
  }
}


### Create Load balancer listener resource redirect 80 to 443
resource "aws_lb_listener" "front_end_alb_80_redirect_to_443" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

   default_action {
    type             = "forward"
     target_group_arn = aws_lb_target_group.alb-diag-tg.arn
     }
#uncomment when redirect to 443 is required
#  default_action {
#    type = "redirect"

#    redirect {
#      port        = "443"
#      protocol    = "HTTPS"
#      status_code = "HTTP_301"
#    }
#  }
}

# If SSL termination at ALB - issue certificate
#resource "aws_lb_listener" "front_end" {
#  load_balancer_arn = aws_lb.alb.arn
#  port              = "443"
#  protocol          = "HTTPS"
#  ssl_policy        = "ELBSecurityPolicy-2016-08"
#  certificate_arn   = "arn:aws:iam::............................"

#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.alb-diag-tg.arn
#  }
#}

###Add authentication??

### ALB security group
resource "aws_security_group" "alb" {
  name   = "${var.alb.alb_name}_alb"
  vpc_id = var.vpc_id

  tags = {
    Environment = var.environment
  }
}

### HTTP ingress
resource "aws_security_group_rule" "https_from_anywhere" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = var.allow_cidr_block
  security_group_id = aws_security_group.alb.id
}

### Outbound open everywhere
resource "aws_security_group_rule" "outbound_internet_access" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}
