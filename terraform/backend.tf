# terraform/backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-340232349940"
    key            = "lambda/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
  }
}
