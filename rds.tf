resource "aws_db_subnet_group" "redmine" {
  name       = "redmine-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "Redmine DB subnet group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_redmine_sg"
  description = "Allow MySQL access from EC2"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] #rango privado de tu VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "redmine" {
  identifier        = "redmine-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  db_name           = var.db_name
  username          = var.db_user
  password          = var.db_password
  port              = var.db_port
  db_subnet_group_name = aws_db_subnet_group.redmine.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot   = true
  publicly_accessible   = false
  multi_az              = false

  tags = {
    Name = "Redmine RDS"
  }
}
