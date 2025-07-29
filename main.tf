# main.tf

# 1. Creo  key en AWS
# aws_key_pair -> recurso de aws donde crea una clave llamada "aws-key"

resource "aws_key_pair" "aws_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# 2. Grupo de seguridad para permitir SSH y HTTP
# aws_security_group  -> recurso de aws para crear un grupo de seguridad llamado "redmine_sg"
# por buena practica, se sugiere no usar aws_security_group con ingress y egress

resource "aws_security_group" "redmine_sg" {
  name        = "redmine_sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id
}

#Conexion ssh port 22
resource "aws_vpc_security_group_ingress_rule" "ssh_ingress" {
  security_group_id = aws_security_group.redmine_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH"
}
#Conexion http port 80 para nginx
resource "aws_vpc_security_group_ingress_rule" "http_ingress" {
  security_group_id = aws_security_group.redmine_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP"
}
#Se usa para que la instancia de EC2 pueda salir a internet
resource "aws_vpc_security_group_egress_rule" "all_egress" {
  security_group_id = aws_security_group.redmine_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" #implica todos los protocolos
  description       = "Allow all outbound traffic"
}

# 3. Instancia EC2 con Ubuntu

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "redmine" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.aws_key.key_name
  subnet_id              = aws_subnet.main_subnet.id
  associate_public_ip_address = true #para que pueda recibir instancia publica
  vpc_security_group_ids = [aws_security_group.redmine_sg.id]

  tags = {
    Name = "RedmineEC2"
  }
}


# Crear VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "redmine-vpc"
  }
}

# Crear subred
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "redmine-subnet"
  }
}

# Gatewat internet

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

#Route table con internet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

