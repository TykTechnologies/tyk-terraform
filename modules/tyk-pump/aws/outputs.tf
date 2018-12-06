output "asg_name" {
  value = "${module.asg.this_autoscaling_group_name}"
}

output "asg_arn" {
  value = "${module.asg.this_autoscaling_group_arn}"
}
