#################################################
# ALB
#################################################
resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "${var.project}-alb-sg"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project}-alb-sg"
    Terraform = "true"
    Owner = "${var.resource_owner}"
  }
}

resource "aws_security_group_rule" "http-ingress-alb" {
  type              = "ingress"
  from_port         = "${var.lb_port}"
  to_port           = "${var.lb_port}"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.alb.id}"
}

resource "aws_security_group_rule" "https-ingress-alb" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.alb.id}"
}

#################################################
# EC2 for Console Access
#################################################
resource "aws_security_group" "ec2" {
  name        = "${var.project}-ec2-sg"
  description = "${var.project}-ec2-sg"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project}-ec2-sg"
    Terraform = "true"
    Owner = "${var.resource_owner}"
  }
}

resource "aws_security_group_rule" "http_ingress-ec2" {
  type                     = "ingress"
  from_port                = "${var.aqua_server_port_01}"
  to_port                  = "${var.aqua_server_port_01}"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.alb.id}"
  security_group_id        = "${aws_security_group.ec2.id}"
}

#################################################
# EC2 for Gateway Access on Classic ELB
#################################################
resource "aws_security_group" "ec2-gateway" {
  name        = "${var.project}-ec2-gw-sg"
  description = "${var.project}-ec2-gw-sg"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project}-ec2-gw-sg"
    Terraform = "true"
    Owner = "${var.resource_owner}"
  }
}

resource "aws_security_group_rule" "gateway_ingress-ec2" {
  type                     = "ingress"
  from_port                = "${var.aqua_server_port_02}"
  to_port                  = "${var.aqua_server_port_02}"
  protocol                 = "tcp"
  # Remember, cidr_blocks must be a list!
  cidr_blocks              = ["${var.vpc_cidr}"]
  security_group_id        = "${aws_security_group.ec2-gateway.id}"
}

#################################################
# RDS
#################################################
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "${var.project}-rds-sg"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project}-rds-sg"
    Terraform = "true"
    Owner = "${var.resource_owner}"
  }
}

resource "aws_security_group_rule" "postgres_ingress-rds" {
  type                     = "ingress"
  from_port                = "${var.postgres_port}"
  to_port                  = "${var.postgres_port}"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.ec2.id}"
  security_group_id        = "${aws_security_group.rds.id}"
}