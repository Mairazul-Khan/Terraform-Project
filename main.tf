terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Provider
provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# VPC
resource "aws_vpc" "devops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "My_Dev_VPC"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "Public_subnet_1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "Public_subnet_2"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.devops_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private_subnet_1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.devops_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private_subnet_2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "devops_igw" {
  vpc_id = aws_vpc.devops_vpc.id

  tags = {
    Name = "Dev_igw"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_igw.id
  }

  tags = {
    Name = "Public_rt"
  }
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for Web Servers
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow SSH, HTTP, HTTPS"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# Security Group for RDS
resource "aws_security_group" "allow_db" {
  name        = "allow_db"
  description = "Allow MySQL from web servers"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_db"
  }
}

# --------- FIXED KEY PAIR ---------
# Option 1: If you already have a key in AWS, just use its name:
variable "key_name" {
  default = "AWS_login"
}

# --------- EC2 Instances ---------
resource "aws_instance" "web1" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y apache2
              systemctl enable apache2
              systemctl start apache2
              echo "<html><body><h1>Welcome to my website - 1!</h1></body></html>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "WebServer1"
  }
}

resource "aws_instance" "web2" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_2.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y apache2
              systemctl enable apache2
              systemctl start apache2
              echo "<html><body><h1>Welcome to my website - 2!</h1></body></html>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "WebServer2"
  }
}

# Application Load Balancer
resource "aws_lb" "web_lb" {
  name               = "web-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.allow_web.id]

  tags = {
    Name = "web-lb"
  }
}

# Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "web-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.devops_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Attach EC2s to Target Group
resource "aws_lb_target_group_attachment" "web1" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web2" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web2.id
  port             = 80
}

# RDS Subnet Group
resource "aws_db_subnet_group" "default" {
  name       = "mydb-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "MyDB Subnet Group"
  }
}

# RDS Instance
resource "aws_db_instance" "mydb" {
  identifier             = "mydb-instance"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "password@123"   # ⚠️ Use SSM/Secrets Manager in real projects
  db_name                = "mydb"
  publicly_accessible    = false
  skip_final_snapshot    = true

  vpc_security_group_ids = [aws_security_group.allow_db.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name

  tags = {
    Name = "My RDS MySQL"
  }
}
