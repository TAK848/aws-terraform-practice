# -------------------------------
# Security group
# -------------------------------
# web security group
resource "aws_security_group" "web_sg" {
  name        = "${var.project}-${var.environment}-web-sg"
  description = "web fronnt role security group"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name    = "${var.project}-${var.environment}-web-sg"
    Project = var.project
    Env     = var.environment
    Type    = "web"
  }
}
resource "aws_security_group_rule" "web_in_http" {
  security_group_id = aws_security_group.web_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "web http in"
}
resource "aws_security_group_rule" "web_in_https" {
  security_group_id = aws_security_group.web_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "web https in"
}
resource "aws_security_group_rule" "web_out_tcp3000" {
  security_group_id        = aws_security_group.web_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 3000
  to_port                  = 3000
  source_security_group_id = aws_security_group.app_sg.id
  description              = "web tcp3000 out"
}

# app security group
resource "aws_security_group" "app_sg" {
  name        = "${var.project}-${var.environment}-app-sg"
  description = "application server role security group"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name    = "${var.project}-${var.environment}-app-sg"
    Project = var.project
    Env     = var.environment
    Type    = "app"
  }
}
resource "aws_security_group_rule" "app_in_tcp3000" {
  security_group_id        = aws_security_group.app_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3000
  to_port                  = 3000
  source_security_group_id = aws_security_group.web_sg.id
  description              = "app tcp3000 in"
}
resource "aws_security_group_rule" "app_out_http" {
  security_group_id = aws_security_group.app_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  prefix_list_ids   = [data.aws_prefix_list.s3_pl.id]
  description       = "app http out"
}
resource "aws_security_group_rule" "app_out_https" {
  security_group_id = aws_security_group.app_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_ids   = [data.aws_prefix_list.s3_pl.id]
  description       = "app https out"
}
resource "aws_security_group_rule" "app_out_tcp3306" {
  security_group_id        = aws_security_group.app_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.db_sg.id
  description              = "app tcp3306 out"
}




# opmng security group
resource "aws_security_group" "opmng_sg" {
  name        = "${var.project}-${var.environment}-opmng-sg"
  description = "operation and management role security group"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name    = "${var.project}-${var.environment}-opmng-sg"
    Project = var.project
    Env     = var.environment
    Type    = "opmng"
  }
}
resource "aws_security_group_rule" "opmng_in_ssh" {
  security_group_id = aws_security_group.opmng_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "opmng ssh in"
}
resource "aws_security_group_rule" "opmng_in_tcp3000" {
  security_group_id = aws_security_group.opmng_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3000
  to_port           = 3000
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "opmng tcp3000 in"
}
resource "aws_security_group_rule" "opmng_out_http" {
  security_group_id = aws_security_group.opmng_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "opmng http out"
}
resource "aws_security_group_rule" "opmng_out_https" {
  security_group_id = aws_security_group.opmng_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "opmng https out"
}

# db security group
resource "aws_security_group" "db_sg" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "database server role security group"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name    = "${var.project}-${var.environment}-db-sg"
    Project = var.project
    Env     = var.environment
    Type    = "db"
  }
}
resource "aws_security_group_rule" "opmng_in_tcp3306" {
  security_group_id        = aws_security_group.db_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.app_sg.id
  description              = "db tcp3306 in"
}
