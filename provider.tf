# provider.tf

#se define que proveedor usará OpenTofu
provider "aws" {
  region = var.aws_region
}
