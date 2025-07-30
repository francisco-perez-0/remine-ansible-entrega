# terraform.tfvars
key_name       = "aws-key"
public_key_path = "~/.ssh/aws.pub"


#asignacion de variables usada por la base de datos
db_password = "redmine_password"
subnet_ids  = ["subnet-0f3e39465a428075f", "subnet-yyyyyy"] #dentro de la vpc hay minimo 2 subnets
vpc_id      = "vpc-003e9182337349a04" #vpc que conecta EC2 con RDS
