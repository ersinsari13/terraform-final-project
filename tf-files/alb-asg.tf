resource "aws_alb_target_group" "target-group" {
  name = "terraform-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = module.my-vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled = true
    healthy_threshold = 2
    interval = 15
    unhealthy_threshold = 3
  }
}

resource "aws_alb" "app-load-balancer" {
  name = "app-load-balancer"
  load_balancer_type = "application"
  security_groups = [aws_security_group.load-balancer-sec-grp.id]
  subnets = [module.my-vpc.public_subnet_id[0],module.my-vpc.public_subnet_id[1],module.my-vpc.public_subnet_id[2]]
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.app-load-balancer.arn
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.certification.arn

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.target-group.arn
  }
}

resource "aws_lb_listener" "redirect-http" {
    load_balancer_arn = aws_alb.app-load-balancer.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "redirect"

    redirect {
        port = "443"
        protocol = "HTTPS"
        status_code = "HTTP_301"
      }
    }
}

resource "aws_autoscaling_group" "terraform-asg" {
    name = "terraform-asg"
    max_size = var.max_size
    min_size = var.min_size
    health_check_grace_period = 300
    health_check_type         = "ELB"
    desired_capacity = var.desired_capacity
    vpc_zone_identifier = module.my-vpc.public_subnet_id
    target_group_arns = [aws_alb_target_group.target-group.arn]

    launch_template {
      id = aws_launch_template.launch-template.id
      version = "$Latest"
    }
}

resource "aws_autoscaling_policy" "target-tracking-policy" {
  name = "asg-policy"
  autoscaling_group_name = aws_autoscaling_group.terraform-asg.name
  policy_type = "TargetTrackingScaling"
  enabled = true

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
