variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Suffix/Prefix for resource naming"
  type        = string
  default     = "Gracy"
}