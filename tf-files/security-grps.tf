resource "aws_security_group" "ec2-sec-grp" {
    name = "ec2-sec-grp"
    vpc_id = module.my-vpc.vpc_id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    dynamic "ingress" {
        for_each = var.port-number
        content {
            from_port = ingress.value
            to_port = ingress.value
            protocol = "tcp"
            security_groups = [aws_security_group.load-balancer-sec-grp.id]
        }
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "load-balancer-sec-grp" {
    name = "load-balancer-sec-grp"
    vpc_id = module.my-vpc.vpc_id

    dynamic "ingress" {
        for_each = var.port-number
        content {
            from_port = ingress.value
            to_port = ingress.value
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "db-sec-grp" {
    name = "db-sec-grp"
    vpc_id = module.my-vpc.vpc_id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.ec2-sec-grp.id]
    }

    egress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.ec2-sec-grp.id]
    }
}