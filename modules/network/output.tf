# Output the VPC Endpoint ID
/*output "vpc_endpoint_id" {
  description = "The ID of the VPC endpoint"
  value       = aws_vpc_endpoint.api_gateway.id
}*/

output "vpc_endpoint_sg_id" {
  description = "The ID of the VPC endpoint security group"
  value       = aws_security_group.vpc_endpoint_sg.id
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.private[*].id # This will output all private subnet IDs
}


