# Create a new load balancer
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_lb_target_group" "growapi-testgroup" {
  name     = "growapi-testgroup"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = "vpc-c8e2e0b2"
}

resource "aws_lb" "growapi-test" {
  name               = "growapi-test"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-030cfa65", "subnet-6e303550", "subnet-74ea182b", "subnet-b5ab00bb", "subnet-d2e915f3", "subnet-eb9011a6", ]
  #availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
  security_groups = ["sg-0822ddbc3a0fec3da"]
}

resource "aws_lb_listener" "growapi-test" {
  load_balancer_arn = aws_lb.growapi-test.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:435852888074:certificate/ced2cb80-eca7-4aec-b674-4c3ddf83ec56"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.growapi-testgroup.arn
  }
}

resource "aws_lb_listener" "growapi-test80" {
  load_balancer_arn = aws_lb.growapi-test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#   listener {
#     instance_port     = 8000
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }

#   listener {
#     instance_port      = 3001
#     instance_protocol  = "http"
#     lb_port            = 443
#     lb_protocol        = "https"
#     ssl_certificate_id = "arn:aws:acm:us-east-1:435852888074:certificate/ced2cb80-eca7-4aec-b674-4c3ddf83ec56"
#   }

#   health_check {
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 3
#     target              = "HTTP:3001/"
#     interval            = 30
#   }

#   instances                   = [aws_instance.foo.id]
#   cross_zone_load_balancing   = true
#   idle_timeout                = 400
#   connection_draining         = true
#   connection_draining_timeout = 400



