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
