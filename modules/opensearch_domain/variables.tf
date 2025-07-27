variable "domain_name" {
  type      = string
  sensitive = true
}

variable "engine_version" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "instance_count" {
  type = number
}

variable "ebs_size" {
  type = number
}

variable "allowed_source_ips" {
  type      = list(string)
  sensitive = true
}

variable "aws_region" {
  description = "Region where the KMS key is created"
  type        = string
}