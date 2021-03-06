variable "vpc_id" {
  type        = string
  description = "VPC to use for Tyk pump"
}

variable "instance_subnets" {
  type        = list(string)
  description = "List of subnets to use for instances"
}

variable "ssh_sg_id" {
  type        = string
  description = "Security group for SSH access"
  default     = ""
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.small"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "min_size" {
  type        = string
  description = "Minimum number of instances in autoscaling group"
  default     = "1"
}

variable "max_size" {
  type        = string
  description = "Maximum number of instance in autoscaling group"
  default     = "2"
}

variable "create_scaling_policies" {
  description = "Create scaling policies and alarm for autoscaling group"
  default     = false
}

variable "pump_config" {
  type        = string
  description = "Full pump config file contents (replaces the default config file if set)"
  default     = ""
}

variable "package_repository" {
  type        = string
  description = "Repository name for the PackageCloud package"
  default     = "tyk-pump"
}

variable "pump_version" {
  type        = string
  description = "Version of Tyk pump to deploy"
}

variable "mongo_url" {
  type        = string
  description = "MongoDB connection string"
  default     = ""
}

variable "mongo_use_ssl" {
  type        = string
  description = "Should MongoDB connection use SSL/TLS?"
  default     = ""
}

variable "redis_host" {
  type        = string
  description = "Redis host"
  default     = ""
}

variable "redis_port" {
  type        = string
  description = "Redis port"
  default     = ""
}

variable "redis_password" {
  type        = string
  description = "Redis password"
  default     = ""
}

variable "redis_enable_cluster" {
  type        = string
  description = "Is Redis clustering enabled?"
  default     = ""
}

variable "redis_hosts" {
  type        = string
  description = "Redis cluster connection parameters"
  default     = ""
}

variable "enable_ssm" {
  description = "Enable AWS Systems Manager"
  default     = false
}

variable "enable_cloudwatch_policy" {
  description = "Enable CloudWatch agent IAM policy for the instance profile"
  default     = false
}

variable "metrics_cloudconfig" {
  type        = string
  description = "Rendered cloud-init config for metrics and logs collection setup"
  default     = ""
}

variable "statsd_conn_str" {
  type        = string
  description = "Connection string for statsd instrumentation"
  default     = ""
}

variable "statsd_prefix" {
  type        = string
  description = "Prefix for statsd metrics"
  default     = "tykPMP"
}
