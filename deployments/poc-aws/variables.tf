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

variable "aws_azs" {
  type        = list(string)
  description = "AWS availability zones for Tyk deployment"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR to use for the new VPC"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet CIDRs"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private (application) subnet CIDRs"
}

variable "elasticache_subnets" {
  type        = list(string)
  description = "List of private ElastiCache subnet CIDRs"
}

variable "docdb_subnets" {
  type        = list(string)
  description = "List of private DocumentDB subnet CIDRs"
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
