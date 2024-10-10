
# LOCALS
locals {
  region           = var.aws_target_region
  region_substring = lower(format("%s%s%s", substr(local.region, 0, 2), substr(local.region, 3, 1), substr(local.region, -1, 1)))
  environment      = terraform.workspace
}

//Network module
module "network" {
  source = "./modules/network"

  environment               = local.environment
  region_substring          = local.region_substring
  vpc_cidr_range            = var.vpc_cidr_range
  project_name              = var.project_name
  private_subnet_cidr_range = var.private_subnet_cidr_range
  public_subnet_cidr_range  = var.public_subnet_cidr_range
}

module "compute" {
  source = "./modules/compute"

  environment         = local.environment
  region_substring    = local.region_substring
  vpce-execute-api-sg = module.network.vpc_endpoint_sg_id
  vpc_id              = module.network.vpc_id
  subnet_id           = module.network.private_subnet_ids[0]
  function_name       = var.lambda_function_name
  project_name        = var.project_name


}

//api gateway module
module "private_api" {
  source = "./modules/private_api"

  vpce_id      = module.network.vpc_endpoint_id
  lambda_arn   = module.compute.lambda_arn
  lambda_name  = module.compute.lambda_name
  project_name = var.project_name
}

# Output the VPC Endpoint ID from the module
output "vpc_endpoint_id" {
  value = module.network.vpc_endpoint_id
}

# Output the VPC Endpoint ID from the module
output "vpc_endpoint_sg_id" {
  value = module.network.vpc_endpoint_sg_id
}