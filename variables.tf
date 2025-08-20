variable "aws_region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "ami_id" {
  default = "ami-020cba7c55df1f615" # ubuntu
}

variable "db_user" {}
variable "db_password" {}