# Specify South America East as AWS provider's region
provider "aws" {
    region = "sa-east-1"
}

# Generate random password for RDS
resource "random_password" "rds_password" {
    length = 16
    special = false
}

# Fetch the default subnet in AZ sa_east_1a
data "aws_subnet" "sa_east_1a" {
    filter {
        name   = "availability-zone"
        values = ["sa-east-1a"]
    }
    filter {
        name   = "default-for-az"
        values = ["true"]
    }
}

# Fetch the default subnet in AZ sa_east_1c
data "aws_subnet" "sa_east_1c" {
    filter {
        name   = "availability-zone"
        values = ["sa-east-1c"]
    }
    filter {
        name   = "default-for-az"
        values = ["true"]
    }
}


# Default subnet group
resource "aws_db_subnet_group" "default" {
  name       = "default-subnet-group"
  subnet_ids = [data.aws_subnet.sa_east_1a.id, data.aws_subnet.sa_east_1c.id]

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

    ingress {
        from_port = 8080
        to_port   = 8080
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Enables communication with Quarkus from anywhere
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

# Get the latest LTS EC2-Ubuntu
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

  owners = ["099720109477"] # Canonical (official Ubuntu)
}


# EC2 Instance (using the AMI fetched above)
resource "aws_instance" "ubuntu_ec2" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"

    key_name = "Ubuntu-Quarkus-Demo"            # Allows user with the key-pair file to SSH connect
    subnet_id = data.aws_subnet.sa_east_1a.id

    vpc_security_group_ids = [aws_security_group.ec2_db_sg.id]

    # user_data = templatefile("${path.module}/ec2_user_data.sh", {})

    tags ={
        Name = "Quarkus-Ubuntu-EC2"
    }
}

# Get latest stable PostgreSQL engine version
data "aws_rds_engine_version" "postgres" {
    engine = "postgres"
}

# RDS PostgreSQL Instance (using the engine version fetched above)
resource "aws_db_instance" "postgres_db" {
    identifier           = "quarkus-postgres-db"
    allocated_storage    = 20
    instance_class       = "db.t3.micro"
    engine               = "postgres"
    engine_version       = data.aws_rds_engine_version.postgres.version
    db_name              = "postgres"
    username             = "postgres"
    password             = random_password.rds_password.result
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