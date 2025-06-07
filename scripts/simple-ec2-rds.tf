# Specify South America East as AWS provider's region
provider "aws" {
    region = "sa-east-1"
}

# Generate random password for RDS
resource "random_password" "rds_password" {
    length = 16
    special = true
}

# Fetch the default VPC in the provided region
data "aws_vpc" "default" {
    default = true
}

# Fetch the subnets in the default VPC
data "aws_subnets" "default" {
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

# Default subnet group
resource "aws_db_subnet_group" "default" {
  name       = "default-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "Default Subnet Group"
  }
}

# Quarkus EC2 Security Group
resource "aws_security_group" "ec2_db_sg" {
    name = "quarkus-ec2-sg"
    description = "Allows access to PostgreSQL and SSH"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Allows SSH ingress from anywhere
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# PostgreSQL RDS Security Group
resource "aws_security_group" "rds_db_sg" {
    name = "quarkus-postgres-db-sg"
    description = "Allows access from Quarkus EC2 instances"

    ingress {
        from_port = 5432
        to_port   = 5432
        protocol  = "tcp"
        security_groups = [aws_security_group.ec2_db_sg.id] # Allows ingress from Quarkus EC2 instance
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# EC2 Instance
resource "aws_instance" "ubuntu_ec2" {
    ami = "ami-0f29c8402f8cce65c"               # Image for Ubuntu 20.04 LTS in sa-east-1
    instance_type = "t2.micro"
    key_name = "Ubuntu-Quarkus-Demo"            # Allows user with the key-pair file to SSH connect
    subnet_id = data.aws_subnets.default.ids[0] # Uses the first available subnet

    vpc_security_group_ids = [aws_security_group.ec2_db_sg.id]

    user_data = templatefile("${path.module}/ec2_user_data.sh", {})

    tags ={
        Name = "Quarkus-Ubuntu-EC2"
    }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres_db" {
    identifier           = "quarkus-postgres-db"
    allocated_storage    = 20
    instance_class       = "db.t3.micro"
    engine               = "postgres"
    engine_version       = "15.3"
    db_name              = "employees-db"
    username             = "postgres"
    password             = random_password.rds_password.result
    parameter_group_name = "default.postgres15"
    skip_final_snapshot  = true
    publicly_accessible  = true
    db_subnet_group_name = aws_db_subnet_group.default.name
    vpc_security_group_ids = [aws_security_group.rds_db_sg.id]
}

# Outputs
output "rds-postgres-endpoint" {
  value = aws_db_instance.postgres_db.endpoint
}

output "rds-postgres-username" {
  value = aws_db_instance.postgres_db.username
}

output "rds-postgres-password" {
  value     = random_password.rds_password.result
  sensitive = true
}