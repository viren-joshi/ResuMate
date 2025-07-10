resource "random_password" "db_password" {
    length  = 20
    special = true

    keepers = {
        secret_version = aws_secretsmanager_secret.db_secret.id
    }
}

resource "aws_secretsmanager_secret" "db_secret" {
  name = "resumate-rds-credentials"
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "resumate_user"
    password = random_password.db_password.result
  })
}

resource "aws_db_subnet_group" "resumate_subnet_group" {
    name = "ResuMateDBSubnetGroup"
    subnet_ids = var.subnet_ids
    tags = {
      Project = "ResuMate"
    }
}

resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "15.5"
  instance_class       = "db.t3.micro"
  identifier           = "resumate-postgres"
  username             = jsondecode(aws_secretsmanager_secret_version.db_secret_version.secret_string)["username"]
  password             = jsondecode(aws_secretsmanager_secret_version.db_secret_version.secret_string)["password"]
  db_subnet_group_name = aws_db_subnet_group.resumate_subnet_group.name
  vpc_security_group_ids = [var.db_security_group_id]
  skip_final_snapshot  = true
  publicly_accessible  = false
}

