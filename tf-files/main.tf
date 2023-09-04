
module "my-vpc" {
    source = "../terraform-creating-vpc"
}

data "aws_ami" "linux-2023" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  filter {
    name = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_launch_template" "launch-template" {
  name = "terarform-lauch-template"
  image_id = data.aws_ami.linux-2023.image_id
  instance_type = var.instance_type
  key_name = var.key_name
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name= "terraform-instance"
    }
  }  
  user_data = base64encode(templatefile("userdata.sh", {git-tokens = var.git-token, db-endpoint= aws_db_instance.database.address }))
  vpc_security_group_ids = [aws_security_group.ec2-sec-grp.id]
  depends_on = [ aws_db_instance.database ]
}

data "aws_acm_certificate" "certification" {
  domain = var.domain_name
  statuses = ["ISSUED"]
}

resource "aws_db_subnet_group" "db-subnet-group" {
  name = "db-subnet-group"
  subnet_ids = [ module.my-vpc.public_subnet_id[0],module.my-vpc.public_subnet_id[1] ]
}

resource "aws_db_instance" "database" {
  allocated_storage = 10
  db_name = "phonebook"
  engine = "mysql"
  engine_version = "8.0.28"
  instance_class = var.instance_class
  username = "admin"
  password = "Oliver_1"
  port = 3306
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.db-sec-grp.id]
  db_subnet_group_name = aws_db_subnet_group.db-subnet-group.name
}
data "aws_route53_zone" "hosted-zone" {
  name = var.domain_name
}

resource "aws_route53_record" "route53-record" {
  zone_id = data.aws_route53_zone.hosted-zone.zone_id
  name = "phonebook.${var.domain_name}"
  type = "A"

  alias {
    name = aws_alb.app-load-balancer.dns_name
    zone_id = aws_alb.app-load-balancer.zone_id
    evaluate_target_health = true
  }
}