variable "program_name" {
  type        = "string"
  description = "Program name to filter the logs by logs"
}

variable "log_group_prefix" {
  type        = "string"
  description = "CloudWatch Logs group name prefix"
  default     = "tyk"
}
