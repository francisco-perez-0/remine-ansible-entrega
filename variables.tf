# variables.tf
variable "aws_region" {
  description = "Región de AWS"
  default     = "us-east-1" # indicada
}

variable "key_name" {
  description = "Nombre del key de AWS"
  type        = string
}

variable "public_key_path" {
  description = "Ruta de clave pública local"
  type        = string
}

# VARIABLES BASE DE DATOS
variable "db_name"     {default = "redmine_production" }
variable "db_user"     { default = "redmine" }
variable "db_password" { sensitive = true }
variable "db_port"     { default = 3306 }
variable "db_instance_class" { default = "db.t3.micro" }
variable "db_allocated_storage" { default = 20 }