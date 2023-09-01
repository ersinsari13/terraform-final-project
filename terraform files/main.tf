terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.14.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
    mytag = "ersin-terraform"
}

data "aws_ami" "linux-2023" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    filter {
        name   = "name"
        values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "template_file" "userdata" {
  template = file("${abspath(path.module)}/userdata.sh")
  vars = {
    db_endpoint =aws_db_instance.db_project.address
  }
}

resource "aws_launch_template" "launch-temp" {
    image_id = data.aws_ami.linux-2023.id
    instance_type = var.instance_type
    name = "launc-temp-ersin"
    key_name = "usa_key"
    vpc_security_group_ids = [aws_security_group.ec2-sec-group.id]
    user_data =  base64encode(data.template_file.userdata.rendered)
   
    tag_specifications {
        resource_type ="instance"
        tags = {
          Name = "terraform-ersin"
        }
    }
    lifecycle {
      create_before_destroy = true
    }
}
resource "aws_security_group" "ec2-sec-group" {
    name = "ec2-sec-group"
    description = "allow 22,80,443"
    
    ingress {
        description = "22 allowed anywhere "
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "80 allowed from load balancer"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.load_balancer.id]
    }
    ingress  {
        description = "3306 allowed RDS DAtabase"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }
    egress  {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }
}
resource "aws_security_group" "load_balancer" {
    name = "load-balancer-sec-group"
    description = "allowed 80,443"

    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }
}  
resource "aws_lb_target_group" "target-group" {
    name        = "ALB-Target-Group"
    port        = 80
    protocol    = "HTTP"
    vpc_id = data.aws_vpc.default-vpc.id
    target_type = "instance"
    tags = {
      "Name" = "${local.mytag}-target-group"
    }
    health_check {
      path                = "/"
      protocol            = "HTTP"
      matcher             = "200"
      interval            = 30
      timeout             = 10
      healthy_threshold   = 3
      unhealthy_threshold = 2
    }
}

data "aws_vpc" "default-vpc" {
  id = var.vpc_id
}
data "aws_subnets" "default-subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default-vpc.id]
  }
}

resource "aws_lb" "ELB" {
    name = "terraform-elb"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default-subnets.ids

    tags = {
      "Name" = "${local.mytag}-ALB"
    }
    security_groups = [aws_security_group.load_balancer.id]
}

resource "aws_lb_listener" "ALB-Listener" {
  load_balancer_arn = aws_lb.ELB.arn 
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

resource "aws_autoscaling_group" "ASG" {
  availability_zones = var.availability_zones
  desired_capacity   = var.desired_capacity 
  max_size           = var.max_size 
  min_size           = var.min_size 
  health_check_grace_period = 300
  health_check_type         = "ELB"

  launch_template {
    id = aws_launch_template.launch-temp.id
    version = "$Latest"
  }

  depends_on = [aws_db_instance.db_project]
}

resource "aws_autoscaling_attachment" "attach-asg" {
    autoscaling_group_name = aws_autoscaling_group.ASG.id
    lb_target_group_arn = aws_lb_target_group.target-group.arn
}

resource "aws_autoscaling_policy" "asg-policy" {
    name = "asg-policy"
    autoscaling_group_name = aws_autoscaling_group.ASG.name
    policy_type = "TargetTrackingScaling"
    
    target_tracking_configuration {
      predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
      }
      target_value = var.target_value
    }
}
resource "aws_db_instance" "db_project" {
  allocated_storage = 8
  db_name = var.db_name
  engine = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class
  username = var.username
  password = var.password
  skip_final_snapshot         = true
  port = 3306
  vpc_security_group_ids = [aws_security_group.db_sec_grp.id]
  tags = {
    Name = "project-db"
  }
}

resource "aws_security_group" "db_sec_grp" {
  name = "db-sec-grp"

  ingress {
    description = "3306 allowed from instance traffic"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.ec2-sec-group.id]
  }

  egress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups = [aws_security_group.ec2-sec-group.id]
  }
}