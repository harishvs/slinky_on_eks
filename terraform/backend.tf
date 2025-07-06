terraform {
  backend "s3" {
    bucket         = "eks-slinky-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-slinky-terraform-locks"
    encrypt        = true
  }
} 