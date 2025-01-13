terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-west-1"
  access_key= "AKIAXEFUNPYDBEJS2LXX"
  secret_key= "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"
}