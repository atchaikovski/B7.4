
variable "region" {
  description = "AWS Region to deploy Server in"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Instance Type"
  type        = string
  default     = "c3.large"
}

variable "enable_detailed_monitoring" {
  type    = bool
  default = false
}

variable "common_tags" {
  description = "Common Tags to apply to all resources"
  type        = map
  default = {
    Owner       = "Alex Tchaikovski"
    Project     = "Small k8s cluster"
    Purpose     = "B7.4"
  }
}

variable "domain_tchaikovski_link" {
  default = "tchaikovski.link"
}

variable "master_host_name" {
  type = string
  default = "master"
}

variable "worker_host_name" {
  type = string
  default = "worker"
}

variable "public_key" {}

variable "private_key" {}
