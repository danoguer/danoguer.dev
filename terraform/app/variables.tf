variable "aws_region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS Region for resources"
}

variable "project_name" {
  type        = string
  default     = "aws-portfolio"
  description = "Name prefix"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

variable "domain_name" {
  description = "danoguer.me"
  type        = string
  default     = "danoguer.me"
}
