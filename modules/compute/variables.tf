variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "vpce-execute-api-sg" {
  description = "The sg associated to the VPCE execute-api"
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

variable "subnet_id" {
  description = "The ID of the subnet where the EC2 instance will be deployed"
  type        = string
}