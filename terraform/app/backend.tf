terraform {
  backend "s3" {
    bucket         = "danoguer-dev-tfstate-portfolio-bucket"
    key            = "app/terraform.tfstate"
    region         = "eu-south-2"
    dynamodb_table = "danoguer-dev-tfstate-locks"
    encrypt        = true
  }
}
