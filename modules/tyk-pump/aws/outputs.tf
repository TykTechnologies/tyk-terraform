output "asg_name" {
  value       = "${module.asg.this_autoscaling_group_name}"
  description = "Name of the auto-scaling group"
}

output "asg_arn" {
  value       = "${module.asg.this_autoscaling_group_arn}"
  description = "ARN of the auto-scaling group"
}
