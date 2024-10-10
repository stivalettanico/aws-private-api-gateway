variable "aws_target_region" {
  description = "this is the region where we want to deploy our application"
  type        = string
}

variable "aws_account_id" {
  description = "this is the account id where we want to deploy our application"
  type        = string
}

variable "account_name" {
  description = "this is the account name where we want to deploy our application"
  type        = string
}

variable "project_name" {
  description = "this is the project we are building"
  type        = string
}

variable "vpc_cidr_range" {
  description = "This is the VPC CIDR range we want to use"
  type        = string
}

variable "public_subnet_cidr_range" {
  description = "This is the CIDR range associated to the public subnets"
  type        = list(string)
}

variable "private_subnet_cidr_range" {
  description = "This is the CIDR range associated to the private subnets"
  type        = list(string)
}

variable "lambda_function_name" {
  description = "This is the name of the lambda function to be integrate with the private API gateway"
  type        = string
}


