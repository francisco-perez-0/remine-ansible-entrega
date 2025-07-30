#ip publica para conexion
output "instance_ip" {
  value = aws_instance.redmine.public_ip
}

# endpoint para conexion
output "rds_endpoint" {
  value = aws_db_instance.redmine.endpoint
}
