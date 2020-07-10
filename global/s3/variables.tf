variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique.  : terraform-s3-docker-registry"
  type        = string
  default = "terraform-s3-docker-registry"
}

variable "table_name" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account.  : terraform-s3-docker-registry-locks"
  type        = string
  default = "terraform-s3-docker-registry-locks"
}
