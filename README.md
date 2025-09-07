# 🌐 AWS Terraform Infrastructure

This repository contains Terraform code to deploy a **highly available web application architecture** on AWS.

## 🚀 Architecture Overview

## Networking

- VPC with CIDR 10.0.0.0/16

- 2 Public Subnets (Web + Load Balancer)

- 2 Private Subnets (RDS Database)

- Internet Gateway & Route Tables for public access

 ## Security

- Security Group: allow_web → SSH (22), HTTP (80), HTTPS (443)

- Security Group: allow_db → MySQL (3306) from web security group only

## Compute & Database

- EC2 Instances (Apache2 web servers in public subnets)

- Application Load Balancer (ALB) distributing traffic across EC2s

- RDS MySQL in private subnets (no public access)**

##  🔑 Prerequisites

- AWS Account

- Terraform (>= 1.0)

- Existing AWS key pair (key_name variable)

- AWS credentials set via:

- Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)

- Or AWS CLI profile

- (Recommended: Use AWS Secrets Manager)

## 📂 Project Structure
```
├── main.tf          # Provider, backend config, high-level resources/modules
├── vpc.tf           # VPC, Subnets, Route Tables, NAT/IGW, Security Groups
├── ec2.tf           # EC2 Instances, Auto Scaling Group, ALB + Target Groups
├── rds.tf           # RDS MySQL, Subnet Group, Parameter Group
├── variables.tf     # Input variables (VPC CIDR, instance type, DB creds, etc.)
├── outputs.tf       # Output values (ALB DNS name, VPC ID, DB endpoint)
└── aws_architecture.png   # Architecture diagram for documentation
```
## 🚀 Deployment Steps

```bash
# Clone the repo
git clone https://github.com/Mairazul-Khan/Terraform-Project.git
cd Terraform-Project

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

```

## 🛑 Cleanup

To destroy all resources:

```sh
terraform destroy
```

---
📌 **Note**: Never hardcode sensitive credentials (use AWS Secrets Manager or environment variables).
