variable "aws_region" {
  type        = string
  description = "AWS region to use for Tyk deployment"
}

variable "aws_access_key" {
  type        = string
  description = "AWS access key to use for Tyk deployment"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret key to use for Tyk deployment"
}

variable "vpc_id" {
  type        = string
  description = "VPC to use for Tyk deployment"
}

variable "instance_subnets" {
  type        = list(string)
  description = "List of subnets to use for instances"
}

variable "lb_subnets" {
  type        = list(string)
  description = "List of subnets to use for load balancing"
}

variable "ssh_sg_id" {
  type        = string
  description = "Security group for SSH access"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "instance_types" {
  type        = map(string)
  description = "Map of EC2 instance types for each component"

  default = {
    dashboard = "t3.small"
    gateway   = "t3.small"
    pump      = "t3.small"
    mdcb      = "t3.small"
  }
}

variable "base_domain" {
  type        = string
  description = "Base domain for the deployment"
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 zone id"
}

variable "redis_host" {
  type        = string
  description = "Redis host"
}

variable "redis_port" {
  type        = string
  description = "Redis port"
}

variable "redis_password" {
  type        = string
  description = "Redis password"
}

variable "mongo_url" {
  type        = string
  description = "MongoDB connection string"
}

variable "mongo_use_ssl" {
  type        = string
  description = "Should MongoDB connection use SSL/TLS?"
}

variable "tyk_license_key" {
  type        = string
  description = "Tyk license"
  default     = ""
}

variable "mdcb_license_key" {
  type        = string
  description = "Tyk MDCB license"
  default     = ""
}

variable "mdcb_token" {
  type        = string
  description = "Repository token for MDCB packages"
  default     = ""
}

variable "tls_certificate_arn" {
  type        = string
  description = "ARN of the TLS certificate resource in ACM"
  default     = ""
}
