resource "aws_security_group" "sg_ssh" {
  name   = "${var.env}-sg_ssh"
  vpc_id = var.vpc_id
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {

    Terraform = "yes"
    Env       = "${var.env}"
    Name      = "${var.env}-sg_ssh"

  }
}

resource "aws_security_group" "sg_web" {
  name   = "${var.env}-sg_web"
  vpc_id = var.vpc_id
  ingress {
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 50000
    to_port         = 50000
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]  # Replace with the actual security group reference
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {

    Terraform = "yes"
    Env       = "${var.env}"
    Name      = "${var.env}-sg_web"

  }
}

resource "aws_security_group_rule" "ingress_to_sg_ec2" {
  type                     = "ingress"
  from_port                = 50000
  to_port                  = 50000
  protocol                 = "tcp"
  security_group_id        = var.ecs_sg_id
  source_security_group_id = aws_security_group.sg_web.id
}
