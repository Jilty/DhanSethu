provider "aws" {
  region = var.region # Change to your desired AWS region
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create public subnet in VPC
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zone1  # Change to your desired AZ
  map_public_ip_on_launch = true
}


# Create private subnet in VPC
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = var.availability_zone2  # Change to your desired AZ
}

# Create S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name  # Change this to a unique bucket name
  
  acl    = "private"
}

# set internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "my_route" {
  route_table_id         = aws_route_table.my_route_table.id
  destination_cidr_block = "0.0.0.0/0"  # Routes all traffic to the internet gateway
  gateway_id             = aws_internet_gateway.my_igw.id
}

resource "aws_route_table_association" "my_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create VPC endpoint for S3
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
}

# create alb security group
resource "aws_security_group" "alb_sg" {
    vpc_id = aws_vpc.my_vpc.id

  name        = "alb-security-group"
  description = "ALB Security Group"

  // Ingress rules allow incoming traffic
  ingress {
    from_port   = 80  # Allow incoming HTTP traffic
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from any IP address (adjust as needed)
  }

  ingress {
    from_port   = 443  # Allow incoming HTTPS traffic
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from any IP address (adjust as needed)
  }

  // Egress rules allow outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outgoing traffic
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic to any IP address (adjust as needed)
  }
}

#Add Alb

resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.alb_sg.id]
  subnets = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id] # Replace these with your subnet IDs in different AZs


  enable_deletion_protection = false

  enable_http2 = true
}

#Add target group in vpc
resource "aws_lb_target_group" "my_target_group" {
  name     = var.targetgroup_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id  # Make sure to define your VPC resource

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout            = 3
    interval           = 30
    path               = "/"
    matcher            = "200-299"
  }
}

# Create security group for instances in private subnet
# resource "aws_security_group" "private_sg" {
#   vpc_id = aws_vpc.my_vpc.id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# Create oracle db 

resource "aws_db_instance" "oracle_db" {
  allocated_storage    = 100  # Size of the database storage in GB
  storage_type        = "gp2" # General Purpose SSD
  engine              = "oracle-ee" # Oracle Database Enterprise Edition
  engine_version      = "19.0.0.0.ru-2021-07.rur-2021-07.r1"  # Example engine version, check for latest version
  instance_class      = "db.t3.medium"  # Example instance type
  db_name             = var.oracledb_name
  username            = var.oracledb_username
  password            = var.oracledb_password
  parameter_group_name = "default.oracle-ee-19"
  skip_final_snapshot       = false
  final_snapshot_identifier = "my-final-snapshot"
}


# Output the bucket name and VPC details
output "bucket_name" {
  value = aws_s3_bucket.my_bucket.id
}

output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}
