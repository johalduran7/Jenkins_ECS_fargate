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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {

    Terraform = "yes"
    Env       = "${var.env}"

  }
}
