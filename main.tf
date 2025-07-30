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

# Regla adicional para permitir conexión a RDS desde EC2
resource "aws_vpc_security_group_ingress_rule" "mysql_ingress" {
  security_group_id = aws_security_group.redmine_sg.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
  description       = "Allow MySQL access from VPC"
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

  owners = ["099720109477"] #limita a busqueda oficiales - ID oficial AWS
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
  map_public_ip_on_launch = true
  tags = {
    Name = "redmine-public-subnet"
  }
}

# Crear subred privada para RDS
resource "aws_subnet" "private_subnet_uno" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "redmine-private-subnet-a"
  }
}

# Crear subred privada para RDS
resource "aws_subnet" "private_subnet_dos" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = false
  tags = {
    Name = "redmine-private-subnet-b"
  }
}

# Elastic IP para NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

# NAT Gateway para la subred privada
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.main_subnet.id

  tags = {
    Name = "redmine-nat-gateway"
  }
}

# Gatewat internet

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

#Route table con internet (publica)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "redmine-public-rt"
  }
}

# Route table privada (para RDS)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "redmine-private-rt"
  }
}

#asocia la table de rutas a la subred pública
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#asocia la table de rutas a la subred privada
resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet_uno.id
  route_table_id = aws_route_table.private_rt.id
}

