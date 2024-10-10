terraform {

  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket               = "my-terraform-state-ns"
    workspace_key_prefix = "eu-west-1/privateapi"
    key                  = "aws.tfstate"
    region               = "eu-west-1"
  }

}