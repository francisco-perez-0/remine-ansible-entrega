#ip publica para conexion
output "instance_ip" {
  value = aws_instance.redmine.public_ip
}

# endpoint para conexion
output "rds_endpoint" {
  value = aws_db_instance.redmine.endpoint
}

# Información de las subredes
output "public_subnet_id" {
  value = aws_subnet.main_subnet.id
}

# VPC ID
output "vpc_id" {
  value = aws_vpc.main.id
}
