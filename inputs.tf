variable "bucket" {
  description = "Name of the bucket to use to store image layers"
  default     = "pipeline-docker-registry-bucket"
}

variable "region" {
  description = "Region to create the AWS resources"
  default     = "eu-west-2"
}

variable "profile" {
  description = "Profile to use when provisioning AWS resources"
  default     = "dev"
}


