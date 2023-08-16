variable "region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "ap-south-2"
}

variable "bucket_name" {
  description = "S3 bucket"
  type        = string
  default = "dansethu-s3-bucket"
}
variable "oracledb_name" {
  description = "oracledb name"
  type        = string
  default = "DhanDB" # less than 8 characters,only alphanumeric value
}

variable "oracledb_username" {
  description = "oracledb username"
  type        = string
  default = "admin"
}

variable "oracledb_password" {
  description = "oracledb password"
  type        = string
  default = "admin1234"
}

variable "availability_zone1" {
  description = "availability zone"
  type        = string
  default = "ap-south-2a"
}

variable "availability_zone2" {
  description = "availability zone"
  type        = string
  default = "ap-south-2b"
}