data "aws_availability_zones" "available" {
  state = "available"
}

# Retrieve the current AWS region
data "aws_region" "current" {}

locals {
  # availablity zones in a specific region
  azs = data.aws_availability_zones.available
}

################################################################################
# VPC
################################################################################
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_range

  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name" = "vpc-${var.project_name}-${var.environment}-${var.region_substring}"
  }
}

################################################################################
# Private subnets
################################################################################
resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidr_range)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidr_range[count.index]
  availability_zone       = local.azs.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    {
      "Name" = "subnet-${var.project_name}-${var.environment}-${local.azs.names[count.index]}-priv"
      "Type" = "Private"
    }
  )
}

################################################################################
# Public subnets
################################################################################
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidr_range)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr_range[count.index]
  availability_zone       = local.azs.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      "Name" = "subnet-${var.project_name}-${var.environment}-${local.azs.names[count.index]}-pub"
      "Type" = "Public"
    }
  )
}

################################################################################
# Internet gateway
################################################################################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      "Name" = "igw-${var.project_name}-${var.environment}-${var.region_substring}"
    }
  )
}

################################################################################
# Creates a public route table to be associated with public subnets
################################################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      "Name" = "rt-${var.project_name}-${var.environment}-${var.region_substring}-pub"
    }
  )
}

################################################################################
# Create elastic IP addresses to be associated with the NAT. We create one EIP for each public subnet to implement HA.
################################################################################
resource "aws_eip" "this" {
  count = length(var.public_subnet_cidr_range)
  tags = merge(
    {
      "Name" = "eip-${var.project_name}-${var.environment}-${var.region_substring}-${local.azs.names[count.index]}"
    }
  )
}

################################################################################
# Create a NAT gateway in each public subnet
################################################################################
resource "aws_nat_gateway" "this" {
  count         = length(var.public_subnet_cidr_range)
  allocation_id = element(aws_eip.this.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = merge(
    {
      "Name" = "nat-${var.project_name}-${var.environment}-${local.azs.names[count.index]}"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.this]
}


################################################################################
# Associate the route table to the public subnets.
################################################################################
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidr_range)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

################################################################################
# Associate the route table to the private subnets.
################################################################################
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr_range)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

################################################################################
# NACL to be associated to the public subnets
################################################################################
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  tags = merge(
    {
      "Name" = "nacl-${var.project_name}-${var.environment}-${var.region_substring}-pub"
    }
  )
}

################################################################################
# NACL to be associated to the private subnets
################################################################################
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.this.id

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  tags = merge(
    {
      "Name" = "nacl-${var.project_name}-${var.environment}-${var.region_substring}-pri"
    }
  )
}

################################################################################
# NACL association with the pubic subnets
################################################################################
resource "aws_network_acl_association" "public" {
  count          = length(var.public_subnet_cidr_range)
  network_acl_id = aws_network_acl.public.id
  subnet_id      = element(aws_subnet.public.*.id, count.index)
}

################################################################################
# NACL association with the private subnets
################################################################################
resource "aws_network_acl_association" "private" {
  count          = length(var.private_subnet_cidr_range)
  network_acl_id = aws_network_acl.private.id
  subnet_id      = element(aws_subnet.private.*.id, count.index)
}


################################################################################
# Create a private route table to be associated with private subnets. Calls will be send to the NAT gateway
################################################################################
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidr_range)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.this.*.id, count.index)
  }

  tags = merge(
    {
      "Name" = "rt-${var.project_name}-${var.environment}-${var.region_substring}-priv-${count.index}"
    }
  )
}

################################################################################
# Define the VPC endpoint for API Gateway (execute-api)
################################################################################
/*resource "aws_vpc_endpoint" "api_gateway" {

  vpc_id             = aws_vpc.this.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private.*.id
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name = "vpce-execute-api-${var.project_name}-${var.environment}-${var.region_substring}"
  }
}*/

################################################################################
# Create a security group for the VPC endpoint
################################################################################
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc-endpoint-sg"
  description = "Security group for the VPC endpoint"
  vpc_id      = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.private_subnet_cidr_range
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  tags = {
    Name = "vpce-execute-api-sg-${var.project_name}-${var.environment}-${var.region_substring}"
  }
}