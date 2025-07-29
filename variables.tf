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
