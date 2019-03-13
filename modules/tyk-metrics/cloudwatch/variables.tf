variable "program_name" {
  type        = "string"
  description = "Program name to filter the logs by"
}

variable "log_group_prefix" {
  type        = "string"
  description = "CloudWatch Logs group name prefix"
  default     = "tyk"
}

variable "metrics_namespace" {
  type        = "string"
  description = "Namespace for custom metrics"
  default     = "TykMetrics"
}