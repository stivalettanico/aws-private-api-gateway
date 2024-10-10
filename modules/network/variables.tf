variable "vpc_cidr_range" {
  description = "This is the VPC CIDR range we want to use"
  type        = string
}

variable "region_substring" {
  description = "This is the region where the VPC resides"
  type        = string
}

variable "environment" {
  description = "Environment, e.g. dev"
  type        = string
}

variable "project_name" {
  description = "This is the project's name"
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