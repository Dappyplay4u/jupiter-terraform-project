# create database subnet group
# terraform aws db subnet group
resource "aws_db_subnet_group" "database_subnet_group" {
  name         = "${var.project_name}-database subnets"
  subnet_ids   = [var.private_data_subnet_az1_id, var.private_data_subnet_az2_id]
  description  = "subnets for database instance"

  tags   = {
    Name ="${var.project_name}-database subnets"
  }
}

resource "aws_db_instance" "database_instance" {
  allocated_storage = 20
  engine = "mysql"
  engine_version = "5.7"
  instance_class = var.database_instance_class
  name = var.db_name
  vpc_security_group_ids  = [var.database_security_group_id]
  username = "admin"
  availability_zone       = "us-east-1b"
  password = var.db_password
  parameter_group_name = "default.mysql5.7"
  multi_az                = false
}
  

# # get the latest db snapshot
# # terraform aws data db snapshot
# data "aws_db_snapshot" "latest_db_snapshot" {
#   db_snapshot_identifier = var.database_snapshot_identifier
#   most_recent            = true
#   snapshot_type          = "manual"
# }

# # create database instance restored from db snapshots
# # terraform aws db instance
# resource "aws_db_instance" "database_instance" {
#   instance_class          = var.database_instance_class
#   skip_final_snapshot     = true
#   availability_zone       = "us-east-1b"
#   identifier              = "dev-rds-db"
#   snapshot_identifier     = data.aws_db_snapshot.latest_db_snapshot.id
#   db_subnet_group_name    = aws_db_subnet_group.database_subnet_group.name
#   multi_az                = false
#   vpc_security_group_ids  = [aws_security_group.database_security_group.id]
# }
