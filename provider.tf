provider "aws" {

  region = var.aws_target_region

  default_tags {
    tags = {
      Account     = var.account_name
      Environment = "${var.project_name}-${terraform.workspace}"
      ManagedBy   = "terraform"
    }
  }

}